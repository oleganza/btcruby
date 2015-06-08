# A collection of routines dealing with parsing and writing protocol messages.
# Various structures have a variable-length data prepended by a length prefix which is itself of variable length.
# This length prefix is a variable-length integer, varint (aka "CompactSize").
#
# NB. varint refers to https://en.bitcoin.it/wiki/Protocol_specification#Variable_length_integer and is what Satoshi called "CompactSize"
# BitcoinQT has later added even more compact format called CVarInt to use in its local block storage. CVarInt is not implemented here.
#
#  Value           Storage length     Format
#  < 0xfd          1                  uint8_t
# <= 0xffff        3                  0xfd followed by the value as little endian uint16_t
# <= 0xffffffff    5                  0xfe followed by the value as little endian uint32_t
#  > 0xffffffff    9                  0xff followed by the value as little endian uint64_t
#
module BTC
  module WireFormat
    extend self

    # Reads varint from data or stream.
    # Either data or stream must be present (and only one of them).
    # Optional offset is useful when reading from data.
    # Returns [value, length] where value is a decoded integer value and length is number of bytes read (including offset bytes).
    # Value may be nil when decoding failed (length might be zero or greater, depending on how much data was consumed before failing).
    # Usage:
    #   i, _ = read_varint(data: buffer, offset: 42)
    #   i, _ = read_varint(stream: File.open('someblock','r'))
    def read_varint(data: nil, stream: nil, offset: 0)
      if data && !stream
        return [nil, 0] if data.bytesize < 1 + offset

        bytes = BTC::Data.bytes_from_data(data, offset: offset, limit: 9) # we don't need more than 9 bytes.

        byte = bytes[0]

        if byte < 0xfd
          return [byte, offset + 1]
        elsif byte == 0xfd
          return [nil, 1] if data.bytesize < 3 + offset # 1 byte prefix, 2 bytes uint16
          return [bytes[1] +
                  bytes[2]*256, offset + 3]
        elsif byte == 0xfe
          return [nil, 1] if data.bytesize < 5 + offset # 1 byte prefix, 4 bytes uint32
          return [bytes[1] +
                  bytes[2]*256 +
                  bytes[3]*256*256 +
                  bytes[4]*256*256*256, offset + 5]
        elsif byte == 0xff
          return [nil, 1] if data.bytesize < 9 + offset # 1 byte prefix, 8 bytes uint64
          return [bytes[1] +
                  bytes[2]*256 +
                  bytes[3]*256*256 +
                  bytes[4]*256*256*256 +
                  bytes[5]*256*256*256*256 +
                  bytes[6]*256*256*256*256*256 +
                  bytes[7]*256*256*256*256*256*256 +
                  bytes[8]*256*256*256*256*256*256*256, offset + 9]
        end

      elsif stream && !data

        if stream.eof?
          raise ArgumentError, "Can't parse varint from stream because it is already closed."
        end

        if offset > 0
          buf = stream.read(offset)
          return [nil, 0] if !buf
          return [nil, buf.bytesize] if buf.bytesize < offset
        end

        prefix = stream.read(1)

        return [nil, offset] if !prefix || prefix.bytesize == 0

        byte = prefix.bytes[0]

        if byte < 0xfd
          return [byte, offset + 1]
        elsif byte == 0xfd
          buf = stream.read(2)
          return [nil, offset + 1] if !buf
          return [nil, offset + 1 + buf.bytesize] if buf.bytesize < 2
          return [buf.unpack("v").first, offset + 3]
        elsif byte == 0xfe
          buf = stream.read(4)
          return [nil, offset + 1] if !buf
          return [nil, offset + 1 + buf.bytesize] if buf.bytesize < 4
          return [buf.unpack("V").first, offset + 5]
        elsif byte == 0xff
          buf = stream.read(8)
          return [nil, offset + 1] if !buf
          return [nil, offset + 1 + buf.bytesize] if buf.bytesize < 8
          return [buf.unpack("Q<").first, offset + 9]
        end

      else
        raise ArgumentError, "Either data or stream must be specified."
      end
    end # read_varint

    # Encodes integer and returns its binary varint representation.
    def encode_varint(i)
      raise ArgumentError, "int must be present" if !i
      raise ArgumentError, "int must be non-negative" if i < 0

      buf = if i <  0xfd
        [i].pack("C")
      elsif i <= 0xffff
        [0xfd, i].pack("Cv")
      elsif i <= 0xffffffff
        [0xfe, i].pack("CV")
      elsif i <= 0xffffffffffffffff
        [0xff, i].pack("CQ<")
      else
        raise ArgumentError, "Does not support integers larger 0xffffffffffffffff (i = 0x#{i.to_s(16)})"
      end

      buf
    end

    # Encodes integer and returns its binary varint representation.
    # If data is given, appends to a data.
    # If stream is given, writes to a stream.
    def write_varint(i, data: nil, stream: nil)
      buf = encode_varint(i)
      data << buf if data
      stream.write(buf) if stream
      buf
    end

    # Reads variable-length string from data buffer or IO stream.
    # Either data or stream must be present (and only one of them).
    # Returns [string, length] where length is a number of bytes read (includes length prefix and offset bytes).
    # In case of failure, returns [nil, length] where length is a number of bytes read before the error was encountered.
    def read_string(data: nil, stream: nil, offset: 0)
      if data && !stream

        string_length, read_length = read_varint(data: data, offset: offset)

        # If failed to read the length prefix, return nil.
        return [nil, read_length] if !string_length

        # Check if we have enough bytes to read the string itself
        return [nil, read_length] if data.bytesize < read_length + string_length

        string = BTC::Data.ensure_binary_encoding(data)[read_length, string_length]

        return [string, read_length + string_length]

      elsif stream && !data

        string_length, read_length = read_varint(stream: stream, offset: offset)
        return [nil, read_length] if !string_length

        buf = stream.read(string_length)

        return [nil, read_length] if !buf
        return [nil, read_length + buf.bytesize] if buf.bytesize < string_length

        return [buf, read_length + buf.bytesize]
      else
        raise ArgumentError, "Either data or stream must be specified."
      end
    end

    # Returns the binary representation of the var-length string.
    def encode_string(string)
      raise ArgumentError, "String must be present" if !string
      encode_varint(string.bytesize) + BTC::Data.ensure_binary_encoding(string)
    end

    # Writes variable-length string to a data buffer or IO stream.
    # If data is given, appends to a data.
    # If stream is given, writes to a stream.
    # Returns the binary representation of the var-length string.
    def write_string(string, data: nil, stream: nil)
      raise ArgumentError, "String must be present" if !string

      intbuf = write_varint(string.bytesize, data: data, stream: stream)

      stringbuf = BTC::Data.ensure_binary_encoding(string)

      data << stringbuf if data
      stream.write(stringbuf) if stream

      intbuf + stringbuf
    end
    
    
    # LEB128 encoding used in Open Assets protocol
    
    # Decodes an unsigned integer encoded in LEB128.
    # Returns `[value, length]` where `value` is an integer decoded from LEB128 and `length` 
    # is a number of bytes read (includes length prefix and offset bytes).
    def read_uleb128(data: nil, stream: nil, offset: 0)
      if (data && stream) || (!data && !stream)
        raise ArgumentError, "Either data or stream must be specified."
      end
      if data
        data = BTC::Data.ensure_binary_encoding(data)
      end
      if stream
        if stream.eof?
          raise ArgumentError, "Can't read LEB128 from stream because it is already closed."
        end
        if offset > 0
          buf = stream.read(offset)
          return [nil, 0] if !buf
          return [nil, buf.bytesize] if buf.bytesize < offset
        end
      end
      result = 0
      shift = 0
      while true
        byte = if data
          return [nil, offset] if data.bytesize < 1 + offset
          BTC::Data.bytes_from_data(data, offset: offset, limit: 1)[0]
        elsif stream
          buf = stream.read(1)
          return [nil, offset] if !buf || buf.bytesize == 0
          buf.bytes[0]
        end
        result |= (byte & 0x7f) << shift
        break if byte & 0x80 == 0
        shift += 7
        offset += 1
      end
      [result, offset + 1]
    end

    # Encodes an unsigned integer using LEB128.
    def encode_uleb128(value)
      raise ArgumentError, "Signed integers are not supported" if value < 0
      return "\x00" if value == 0
      bytes = []
      while value != 0
        byte = value & 0b01111111 # 0x7f
        value >>= 7
        if value != 0
          byte |= 0b10000000 # 0x80
        end
        bytes << byte
      end
      return BTC::Data.data_from_bytes(bytes)
    end

    # Writes an unsigned integer encoded in LEB128 to a data buffer or a stream.
    # Returns LEB128-encoded binary string.
    def write_uleb128(value, data: nil, stream: nil)
      raise ArgumentError, "Integer must be present" if !value
      buf = encode_uleb128(value)
      data << buf if data
      stream.write(buf) if stream
      buf
    end
    
    

    PACK_FORMAT_UINT8    = "C".freeze
    PACK_FORMAT_INT8     = "c".freeze
    PACK_FORMAT_UINT16LE = "S<".freeze
    PACK_FORMAT_INT16LE  = "s<".freeze
    PACK_FORMAT_UINT32LE = "L<".freeze
    PACK_FORMAT_INT32LE  = "l<".freeze
    PACK_FORMAT_UINT32BE = "L>".freeze # used in BIP32
    PACK_FORMAT_UINT64LE = "Q<".freeze
    PACK_FORMAT_INT64LE  = "q<".freeze

    # These read fixed-length integer in appropriate format ("le" stands for "little-endian")
    # Return [value, length] or [nil, length] just like #read_varint method (see above).
    def read_uint8(data: nil, stream: nil, offset: 0)
      _read_fixint(name: :uint8,    length: 1, pack_format: PACK_FORMAT_UINT8,    data: data, stream: stream, offset: offset)
    end

    def read_int8(data: nil, stream: nil, offset: 0)
      _read_fixint(name: :int8,     length: 1, pack_format: PACK_FORMAT_INT8,     data: data, stream: stream, offset: offset)
    end

    def read_uint16le(data: nil, stream: nil, offset: 0)
      _read_fixint(name: :uint16le, length: 2, pack_format: PACK_FORMAT_UINT16LE, data: data, stream: stream, offset: offset)
    end

    def read_int16le(data: nil, stream: nil, offset: 0)
      _read_fixint(name: :int16le,  length: 2, pack_format: PACK_FORMAT_INT16LE,  data: data, stream: stream, offset: offset)
    end

    def read_uint32le(data: nil, stream: nil, offset: 0)
      _read_fixint(name: :uint32le, length: 4, pack_format: PACK_FORMAT_UINT32LE, data: data, stream: stream, offset: offset)
    end

    def read_int32le(data: nil, stream: nil, offset: 0)
      _read_fixint(name: :int32le,  length: 4, pack_format: PACK_FORMAT_INT32LE,  data: data, stream: stream, offset: offset)
    end
    
    def read_uint32be(data: nil, stream: nil, offset: 0) # used in BIP32
      _read_fixint(name: :uint32be, length: 4, pack_format: PACK_FORMAT_UINT32BE, data: data, stream: stream, offset: offset)
    end

    def read_uint64le(data: nil, stream: nil, offset: 0)
      _read_fixint(name: :uint64le, length: 8, pack_format: PACK_FORMAT_UINT64LE, data: data, stream: stream, offset: offset)
    end

    def read_int64le(data: nil, stream: nil, offset: 0)
      _read_fixint(name: :int64le,  length: 8, pack_format: PACK_FORMAT_INT64LE,  data: data, stream: stream, offset: offset)
    end

    # Encode int into one of the formats
    def encode_uint8(int);    [int].pack(PACK_FORMAT_UINT8);    end
    def encode_int8(int);     [int].pack(PACK_FORMAT_INT8);     end
    def encode_uint16le(int); [int].pack(PACK_FORMAT_UINT16LE); end
    def encode_int16le(int);  [int].pack(PACK_FORMAT_INT16LE);  end
    def encode_uint32le(int); [int].pack(PACK_FORMAT_UINT32LE); end
    def encode_int32le(int);  [int].pack(PACK_FORMAT_INT32LE);  end
    def encode_uint32be(int); [int].pack(PACK_FORMAT_UINT32BE); end # used in BIP32
    def encode_uint64le(int); [int].pack(PACK_FORMAT_UINT64LE); end
    def encode_int64le(int);  [int].pack(PACK_FORMAT_INT64LE);  end


    protected

    def _read_fixint(name: nil, length: nil, pack_format: nil, data: nil, stream: nil, offset: 0)
      if data && !stream

        if data.bytesize < offset + length
          Diagnostics.current.add_message("BTC::WireFormat#read_#{name}: Not enough bytes to read #{name} in binary string.")
          return [nil, 0]
        end

        if offset > 0
          pack_format = "@#{offset}" + pack_format
        end

        return [data.unpack(pack_format).first, offset + length]

      elsif stream && !data

        if offset > 0
          buf = stream.read(offset)
          return [nil, 0] if !buf
          return [nil, buf.bytesize] if buf.bytesize < offset
        end

        buf = stream.read(length)

        if !buf
          Diagnostics.current.add_message("BTC::WireFormat#read_#{name}: Failed to read #{name} from stream.")
          return [nil, offset]
        end

        if buf.bytesize < length
          Diagnostics.current.add_message("BTC::WireFormat#read_#{name}: Not enough bytes to read #{name} from stream.")
          return [nil, offset + buf.bytesize]
        end

        return [buf.unpack(pack_format).first, offset + length]

      else
        raise ArgumentError, "BTC::WireFormat#read_#{name}: Either data or stream must be specified."
      end
    end

  end
end
