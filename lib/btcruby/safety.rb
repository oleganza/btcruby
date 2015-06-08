module BTC

  # Several functions intended to detect bad data in runtime and throw exceptions.
  # These are for programmer's errors, not for bad user input.
  # Bad user input should never raise exceptions.
  module Safety
    def AssertType(value, type)
      if !value.is_a?(type)
        raise ArgumentError, "Value #{value.inspect} must be of type #{type}!"
      end
    end
    def AssertTypeOrNil(value, type)
      return if value == nil
      AssertType(value, type)
    end

    # Checks invariant and raises an exception.
    def Invariant(condition, message)
      if !condition
        raise RuntimeError, "BTC Invariant Failure: #{message}"
      end
    end
  end

  include Safety
end
