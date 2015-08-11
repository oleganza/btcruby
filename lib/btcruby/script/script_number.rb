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

if $0 == __FILE__
  require 'btcruby'

  include BTC
  def run_tests

    # Decoding

    [-1000000000000000,-10000,-100,-1,0,1,10,1000,100000000000000].each do |i|
      should_equal(ScriptNumber.new(integer: i).to_i, i, "Must return integer as-is.")
    end

    should_equal(ScriptNumber.new(data: "").to_i,          0,   "Must parse empty string as zero.")
    should_equal(ScriptNumber.new(data: "\x01").to_i,      1,   "Must parse 0x01 as 1.")
    should_equal(ScriptNumber.new(data: "\xff").to_i,     -127, "Must parse 0xff as -127.")
    should_equal(ScriptNumber.new(data: "\xff\x00").to_i,  255, "Must parse 0xff00 as 255.")
    should_equal(ScriptNumber.new(data: "\x81").to_i,     -1,   "Must parse 0x81 as -1.")
    should_equal(ScriptNumber.new(data: "\x8f").to_i,     -15,  "Must parse 0x8f as -0x0f.")
    should_equal(ScriptNumber.new(data: "\x00\x81").to_i, -256, "Must parse 0x0081 as -256.")
    should_equal(ScriptNumber.new(data: "\xff\x80").to_i, -255, "Must decode -255.")

    should_raise('non-minimally encoded script number') { ScriptNumber.new(data: "\x00") }
    should_raise('non-minimally encoded script number') { ScriptNumber.new(data: "\x80") }
    should_raise('non-minimally encoded script number') { ScriptNumber.new(data: "\x00\x80") }
    should_raise('non-minimally encoded script number') { ScriptNumber.new(data: "\x01\x80") }
    should_raise('non-minimally encoded script number') { ScriptNumber.new(data: "\x00\x00\x80") }
    should_raise('non-minimally encoded script number') { ScriptNumber.new(data: "\x00\x10\x80") }
    should_raise('non-minimally encoded script number') { ScriptNumber.new(data: "\x10\x00\x80") }
    should_raise('script number overflow (3 > 2)')      { ScriptNumber.new(data: "\x00\x00\x80", max_size: 2) }

    # Encoding

    should_equal(ScriptNumber.new(integer:  0).to_hex,      "")
    should_equal(ScriptNumber.new(integer:  1).to_hex,      "01")
    should_equal(ScriptNumber.new(integer: -1).to_hex,      "81")
    should_equal(ScriptNumber.new(integer:  255).to_hex,    "ff00")
    should_equal(ScriptNumber.new(integer: -255).to_hex,    "ff80")
    should_equal(ScriptNumber.new(integer:  0xffff).to_hex, "ffff00")
    should_equal(ScriptNumber.new(integer: -0xffff).to_hex, "ffff80")

    # Back and forth test

    (-100000..10000).each do |i|
      d = ScriptNumber.new(integer: i).data
      #puts BTC.to_hex(d) if i % 16 == 0
      i2 = ScriptNumber.new(data: d).to_i
      should_equal(i, i2)
    end
    
    # Booleans
    
    should_equal(ScriptNumber.new(boolean: true), 1)
    should_equal(ScriptNumber.new(boolean: false), 0)

    # Equality

    should_equal(ScriptNumber.new(integer: 0) == 0, true)
    should_equal(ScriptNumber.new(integer: 1) == 1, true)
    should_equal(ScriptNumber.new(integer: -1) == -1, true)

    should_equal(ScriptNumber.new(integer: 0) == ScriptNumber.new(integer: 0), true)
    should_equal(ScriptNumber.new(integer: 1) == ScriptNumber.new(integer: 1), true)
    should_equal(ScriptNumber.new(integer: -1) == ScriptNumber.new(integer: -1), true)
    
    should_equal(ScriptNumber.new(integer: 0) != 0, false)
    should_equal(ScriptNumber.new(integer: 1) != 1, false)
    should_equal(ScriptNumber.new(integer: -1) != -1, false)

    should_equal(ScriptNumber.new(integer: 0) != ScriptNumber.new(integer: 0), false)
    should_equal(ScriptNumber.new(integer: 1) != ScriptNumber.new(integer: 1), false)
    should_equal(ScriptNumber.new(integer: -1) != ScriptNumber.new(integer: -1), false)
    
    # Arithmetic
    
    sn = ScriptNumber.new(integer: 123)
    sn -= 1
    should_equal(sn, 122)
    
    puts "All tests passed."
  end

  def should_equal(a, b, msg = 'Must equal')
    a == b or raise "#{msg} Expected #{b.inspect}, received #{a.inspect}."
  end

  def should_raise(message)
    raised = false
    begin
      yield
    rescue => e
      if e.message == message
        raised = true
      else
        raise "Raised unexpected exception: #{e}"
      end
    end
    if !raised
      raise "Should have raised #{message.inspect}!"
    end
  end

  run_tests
end



