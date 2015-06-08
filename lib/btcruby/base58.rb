module BTC
  # Base58 is used for compact human-friendly representation of Bitcoin addresses and private keys.
  # Typically Base58-encoded text also contains a checksum (so-called "Base58Check").
  # Addresses look like 19FGfswVqxNubJbh1NW8A4t51T9x9RDVWQ.
  # Private keys look like 5KQntKuhYWSRXNqp2yhdXzjekYAR7US3MT1715Mbv5CyUKV6hVe.
  #
  # Here is what Satoshi said about Base58:
  # Why base-58 instead of standard base-64 encoding?
  # - Don't want 0OIl characters that look the same in some fonts and
  #      could be used to create visually identical looking account numbers.
  # - A string with non-alphanumeric characters is not as easily accepted as an account number.
  # - E-mail usually won't line-break if there's no punctuation to break at.
  # - Double-clicking selects the whole number as one word if it's all alphanumeric.
  #
  module Base58
    extend self

    ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz".freeze

    # Converts binary string into its Base58 representation.
    # If string is empty returns an empty string.
    # If string is nil raises ArgumentError
    def base58_from_data(data)
      raise ArgumentError, "Data is missing" if !data
      leading_zeroes = 0
      int = 0
      base = 1
      data.bytes.reverse_each do |byte|
        if byte == 0
          leading_zeroes += 1
        else
          leading_zeroes = 0
          int += base*byte
        end
        base *= 256
      end
      return ("1"*leading_zeroes) + base58_from_int(int)
    end

    # Converts binary string into its Base58 representation.
    # If string is empty returns an empty string.
    # If string is nil raises ArgumentError.
    def data_from_base58(string)
      raise ArgumentError, "String is missing" if !string
      int = int_from_base58(string)
      bytes = []
      while int > 0
        remainder = int % 256
        int = int / 256
        bytes.unshift(remainder)
      end
      data = BTC::Data.data_from_bytes(bytes)
      byte_for_1 = "1".bytes.first
      BTC::Data.ensure_ascii_compatible_encoding(string).bytes.each do |byte|
        break if byte != byte_for_1
        data = "\x00" + data
      end
      data
    end

    def base58check_from_data(data)
      raise ArgumentError, "Data is missing" if !data
      return base58_from_data(data + BTC.hash256(data)[0,4])
    end

    def data_from_base58check(string)
      data = data_from_base58(string)
      if data.bytesize < 4
        raise FormatError, "Invalid Base58Check string: too short string #{string.inspect}"
      end
      payload_size = data.bytesize - 4
      payload = data[0, payload_size]
      checksum = data[payload_size, 4]
      if checksum != BTC.hash256(payload)[0,4]
        raise FormatError, "Invalid Base58Check string: checksum invalid in #{string.inspect}"
      end
      payload
    end

    private

    def base58_from_int(int)
      raise ArgumentError, "Integer is missing" if !int
      string = ''
      base = ALPHABET.size
      while int > 0
        int, remainder = int.divmod(base)
        string = ALPHABET[remainder] + string
      end
      return string
    end

    def int_from_base58(string)
      raise ArgumentError, "String is missing" if !string
      int = 0
      base = ALPHABET.size
      string.reverse.each_char.with_index do |char,index|
        char_index = ALPHABET.index(char)
        if !char_index
          raise FormatError, "Invalid Base58 character: #{char.inspect} at index #{index} (full string: #{string.inspect})"
        end
        int += char_index*(base**index)
      end
      int
    end

  end
end
