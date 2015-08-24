module BTC
  # (Based on CScriptNum)
  # Numeric opcodes (OP_1ADD, etc) are restricted to operating on 4-byte integers.
  # The semantics are subtle, though: operands must be in the range [-2^31 +1...2^31 -1],
  # but results may overflow (and are valid as long as they are not used in a subsequent
  # numeric operation). ScriptNumber enforces those semantics by storing results as
  # an int64 and allowing out-of-range values to be returned as a vector of bytes but
  # throwing an exception if arithmetic is done or the result is interpreted as an integer.
  class ScriptNumberError < ArgumentError; end

  class ScriptNumber
    DEFAULT_MAX_SIZE = 4
    
    INT64_MAX = 0x7fffffffffffffff
    INT64_MIN = -INT64_MAX - 1

    def initialize(integer: nil, boolean: nil, data: nil, hex: nil, require_minimal: true, max_size: DEFAULT_MAX_SIZE)
      if integer
        assert(integer >= INT64_MIN && integer <= INT64_MAX, "Integer must be within int64 range")
        @integer = integer
      elsif boolean == false || boolean == true
        @integer = boolean ? 1 : 0
      elsif data || hex
        data ||= BTC.from_hex(hex)
        if data.bytesize > max_size
          raise ScriptNumberError, "script number overflow (#{data.bytesize} > #{max_size})"
        end
        if require_minimal && data.bytesize > 0
          # Check that the number is encoded with the minimum possible
          # number of bytes.
          #
          # If the most-significant-byte - excluding the sign bit - is zero
          # then we're not minimal. Note how this test also rejects the
          # negative-zero encoding, 0x80.
          if (data.bytes.last & 0x7f) == 0
            # One exception: if there's more than one byte and the most
            # significant bit of the second-most-significant-byte is set
            # it would conflict with the sign bit. An example of this case
            # is +-255, which encode to 0xff00 and 0xff80 respectively.
            # (big-endian).
            if data.bytesize <= 1 || (data.bytes[data.bytesize - 2] & 0x80) == 0
              raise ScriptNumberError, "non-minimally encoded script number"
            end
          end
        end
        @integer = self.class.decode_integer(data)
      else
        raise ArgumentError
      end
    end

    # Operators

    def ==(other); @integer == other.to_i; end
    def !=(other); @integer != other.to_i; end
    def <=(other); @integer <= other.to_i; end
    def  <(other); @integer  < other.to_i; end
    def >=(other); @integer >= other.to_i; end
    def  >(other); @integer  > other.to_i; end
    
    def +(other); self.class.new(integer: @integer + other.to_i); end
    def -(other); self.class.new(integer: @integer - other.to_i); end
    
    def +@
      self
    end

    def -@
      assert(@integer > INT64_MIN && @integer <= INT64_MAX, "Integer will not be within int64 range after negation")
      self.class.new(integer: -@integer)
    end
    


    # Conversion Methods

    def to_i
      @integer
    end

    def to_s
      @integer.to_s
    end

    def data
      self.class.encode_integer(@integer)
    end

    def to_hex
      BTC.to_hex(data)
    end

    def self.decode_integer(data)
      return 0 if data.empty?

      result = 0

      bytes = data.bytes
      bytes.each_with_index do |byte, i|
        result |= bytes[i] << 8*i
      end

      # If the input vector's most significant byte is 0x80, remove it from
      # the result's msb and return a negative.
      if (bytes.last & 0x80) != 0
        return -(result & ~(0x80 << (8 * (bytes.size - 1))));
      end
      return result
    end

    def self.encode_integer(value)
      return "".b if value == 0

      result = []
      negative = value < 0
      absvalue = negative ? -value : value

      while absvalue != 0
        result.push(absvalue & 0xff)
        absvalue >>= 8
      end

      # - If the most significant byte is >= 0x80 and the value is positive, push a
      # new zero-byte to make the significant byte < 0x80 again.
      #
      # - If the most significant byte is >= 0x80 and the value is negative, push a
      # new 0x80 byte that will be popped off when converting to an integral.
      #
      # - If the most significant byte is < 0x80 and the value is negative, add
      # 0x80 to it, since it will be subtracted and interpreted as a negative when
      # converting to an integral.

      if (result.last & 0x80) != 0
        result.push(negative ? 0x80 : 0)
      elsif negative
        result[result.size - 1] = result.last | 0x80
      end

      BTC.data_from_bytes(result)
    end
    
    def assert(condition, message)
      raise message if !condition
    end

  end
end
