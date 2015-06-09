require 'securerandom'

module BTC
  
  # This allows doing `BTC.to_hex(...)`
  module Data; end
  include Data
  extend self
  
  module Data
    extend self
    
    HEX_PACK_CODE = "H*".freeze
    BYTE_PACK_CODE = "C*".freeze

    # Generates a secure random number of a given length
    def random_data(length = 32)
      SecureRandom.random_bytes(length)
    end

    # Converts hexadecimal string to a binary data string.
    def data_from_hex(hex_string)
      raise ArgumentError, "Hex string is missing" if !hex_string
      hex_string = hex_string.strip
      data = [hex_string].pack(HEX_PACK_CODE)
      if hex_from_data(data) != hex_string.downcase # invalid hex string was detected
        raise FormatError, "Hex string is invalid: #{hex_string.inspect}"
      end
      return data
    end

    # Converts binary string to lowercase hexadecimal representation.
    def hex_from_data(data)
      raise ArgumentError, "Data is missing" if !data
      return data.unpack(HEX_PACK_CODE).first
    end
    
    def to_hex(data)
      hex_from_data(data)
    end
    
    def from_hex(hex)
      data_from_hex(hex)
    end

    # Converts a binary string to an array of bytes (list of integers).
    # Returns a much more efficient slice of bytes if offset/limit or
    # range are specified. That is, avoids converting the entire buffer to byte array.
    #
    # Note 1: if range is specified, it takes precedence over offset/limit.
    #
    # Note 2: byteslice(...).bytes is less efficient as it creates
    #         an intermediate shorter string.
    #
    def bytes_from_data(data, offset: 0, limit: nil, range: nil)
      raise ArgumentError, "Data is missing" if !data
      if offset == 0 && limit == nil && range == nil
        return data.bytes
      end
      if range
        offset = range.begin
        limit  = range.size
      end
      bytes = []
      data.each_byte do |byte|
        if offset > 0
          offset -= 1
        else
          if !limit || limit > 0
            bytes << byte
            limit -= 1 if limit
          else
            break
          end
        end
      end
      bytes
    end

    # Converts binary string to an array of bytes (list of integers).
    def data_from_bytes(bytes)
      raise ArgumentError, "Bytes are missing" if !bytes
      bytes.pack(BYTE_PACK_CODE)
    end

    # Returns string as-is if it is ASCII-compatible
    # (that is, if you are interested in 7-bit characters exposed as #bytes).
    # If it is not, attempts to transcode to UTF8 replacing invalid characters if there are any.
    # If options are not specified, uses safe default that replaces unknown characters with standard character.
    # If options are specified, they are used as-is for String#encode method.
    def ensure_ascii_compatible_encoding(string, options = nil)
      if string.encoding.ascii_compatible?
        string
      else
        string.encode(Encoding::UTF_8, options || {:invalid => :replace, :undef => :replace})
      end
    end

    # Returns string as-is if it is already encoded in binary encoding (aka BINARY or ASCII-8BIT).
    # If it is not, converts to binary by calling stdlib's method #b.
    def ensure_binary_encoding(string)
      raise ArgumentError, "String is missing" if !string
      if string.encoding == Encoding::BINARY
        string
      else
        string.b
      end
    end

  end
end
