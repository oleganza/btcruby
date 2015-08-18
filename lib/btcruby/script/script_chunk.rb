module BTC
  # ScriptChunk represents either an opcode or a pushdata command.
  class ScriptChunk
    # Raw data for this chunk.
    # 1 byte for regular opcode, 1 or more bytes for pushdata command.
    # We do not call it 'data' to avoid confusion with `pushdata` (see below).
    # The encoding is guaranteed to be binary.
    attr_reader :raw_data

    # Opcode for this chunk (first byte of the raw_data).
    attr_reader :opcode

    # If opcode is OP_PUSHDATA*, contains pure data being pushed.
    # If opcode is OP_0, returns an empty string.
    # If opcode is not pushdata, returns nil.
    attr_reader :pushdata

    # Length of raw_data in bytes.
    attr_reader :size
    alias :length :size

    # Returns true if this is a non-pushdata (also not OP_0) opcode.
    def opcode?
      !pushdata?
    end

    # Returns true if this is a pushdata chunk (or OP_0 opcode).
    def pushdata?
      # Compact pushdata opcodes are "virtual", just length prefixes.
      # Attention: OP_0 is also "pushdata" code that pushes empty data.
      opcode <= OP_PUSHDATA4
    end

    def data_only?
      opcode <= OP_16
    end

    # Returns true if this chunk is in canonical form (the most compact one).
    # Returns false if it contains pushdata with too big length prefix.
    # Example of non-canonical chunk: 75 bytes pushed with OP_PUSHDATA1 instead
    # of simple 0x4b prefix.
    # Note: this is not as strict as `check_minimal_push` in ScriptInterpreter.
    def canonical?
      opcode = self.opcode
      if opcode < OP_PUSHDATA1
        return true # most compact pushdata is always canonical.
      elsif opcode == OP_PUSHDATA1
        return (self.raw_data.bytesize - (1+1)) >= OP_PUSHDATA1
      elsif opcode == OP_PUSHDATA2
        return (self.raw_data.bytesize - (1+2)) > 0xff
      elsif opcode == OP_PUSHDATA4
        return (self.raw_data.bytesize - (1+4)) > 0xffff
      else
        return true # all other opcodes are canonical (just 1 byte code)
      end
    end

    def opcode
      # raises StopIteration if raw_data is empty,
      # but we don't allow empty raw_data for chunks.
      raw_data.each_byte.next
    end

    def pushdata
      return nil if !pushdata?
      opcode = self.opcode
      offset = 1 # by default, opcode is just a length prefix.
      if opcode == OP_PUSHDATA1
        offset += 1
      elsif opcode == OP_PUSHDATA2
        offset += 2
      elsif opcode == OP_PUSHDATA4
        offset += 4
      end
      self.raw_data[offset, self.raw_data.size - offset]
    end
    
    # Returns corresponding data for data_only opcodes:
    # pushdata or OP_N-encoded numbers.
    # For all other opcodes returns nil.
    def interpreted_data
      if d = pushdata
        return d
      end
      opcode = self.opcode
      if opcode == OP_1NEGATE || (opcode >= OP_1 && opcode <= OP_16)
        ScriptNumber.new(integer: opcode - OP_1 + 1).data
      else
        nil
      end
    end

    def size
      self.raw_data.bytesize
    end

    def to_s
      opcode = self.opcode

      if self.opcode?
        return "OP_0"       if opcode == OP_0
        return "OP_1NEGATE" if opcode == OP_1NEGATE
        if opcode >= OP_1 && opcode <= OP_16
          return "OP_#{opcode + 1 - OP_1}"
        end
        return Opcode.name_for_opcode(opcode)
      end

      pushdata = self.pushdata
      return "OP_0" if pushdata.bytesize == 0 # Empty data is encoded as OP_0.

      string = ""

      # If it's some weird readable string, show it as a readable string.
      if data_is_ascii_printable?(pushdata) && (pushdata.bytesize < 20 || pushdata.bytesize > 65)
        string = pushdata.encode(Encoding::ASCII)
        # Escape escapes & single quote characters.
        string.gsub!("\\", "\\\\")
        string.gsub!("'", "\\'")
        # Wrap in single quotes. Why not double? Because they are already used in JSON and we don't want to multiply the mess.
        string = "'#{string}'"
      else
        string = BTC.to_hex(pushdata)
        # Shorter than 128-bit chunks are wrapped in square brackets to avoid ambiguity with big all-decimal numbers.
        if (pushdata.bytesize < 16)
            string = "[#{string}]"
        end
      end

      # Pushdata with non-compact encoding will have explicit length prefix (1 for OP_PUSHDATA1, 2 for OP_PUSHDATA2 and 4 for OP_PUSHDATA4).
      if !canonical?
        prefix = 1
        prefix = 2 if opcode == OP_PUSHDATA2
        prefix = 4 if opcode == OP_PUSHDATA4
        string = "#{prefix}:#{string}"
      end

      return string
    end

    # Parses the chunk with binary data. Assumes the encoding is binary.
    def self.with_data(data, offset: 0)
      raise ArgumentError, "Data is missing" if !data

      opcode, _ = BTC::WireFormat.read_uint8(data: data, offset: offset)

      raise ArgumentError, "Failed to read opcode of the script chunk" if !opcode

      # push data opcode
      if opcode <= OP_PUSHDATA4

        length = data.bytesize

        if opcode < OP_PUSHDATA1
          pushdata_length = opcode
          chunk_length = 1 + pushdata_length
          if offset + chunk_length > length
            raise ArgumentError, "PUSHDATA is longer than we have bytes available"
          end
          return self.new(data[offset, chunk_length])
        elsif opcode == OP_PUSHDATA1
          pushdata_length, _ = BTC::WireFormat.read_uint8(data: data, offset: offset + 1)
          if !pushdata_length
            raise ArgumentError, "Failed to read length for PUSHDATA1"
          end
          chunk_length = 1 + 1 + pushdata_length
          if offset + chunk_length > length
            raise ArgumentError, "PUSHDATA1 is longer than we have bytes available"
          end
          return self.new(data[offset, chunk_length])
        elsif (opcode == OP_PUSHDATA2)
          pushdata_length, _ = BTC::WireFormat.read_uint16le(data: data, offset: offset + 1)
          if !pushdata_length
            raise ArgumentError, "Failed to read length for PUSHDATA2"
          end
          chunk_length = 1 + 2 + pushdata_length
          if offset + chunk_length > length
            raise ArgumentError, "PUSHDATA2 is longer than we have bytes available"
          end
          return self.new(data[offset, chunk_length])
        elsif (opcode == OP_PUSHDATA4)
          pushdata_length, _ = BTC::WireFormat.read_uint32le(data: data, offset: offset + 1)
          if !pushdata_length
            raise ArgumentError, "Failed to read length for PUSHDATA4"
          end
          chunk_length = 1 + 4 + pushdata_length
          if offset + chunk_length > length
            raise ArgumentError, "PUSHDATA4 is longer than we have bytes available"
          end
          return self.new(data[offset, chunk_length])
        end
      else
        # simple opcode - 1 byte
        return self.new(data[offset, 1])
      end
    end

    def initialize(raw_data)
      @raw_data = raw_data
    end

    def ==(other)
      @raw_data == other.raw_data
    end

    protected

    def data_is_ascii_printable?(data)
      data.each_byte do |byte|
        return false if !(byte >= 0x20 && byte <= 0x7E)
      end
      return true
    end

  end # ScriptChunk
end
