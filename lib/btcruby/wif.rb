module BTC
  # Private key in Wallet Import Format (WIF aka Sipa format).
  # Examples: 5KQntKuhYWSRXNq... or L3p8oAcQTtuokSC...
  class WIF < Address

    KEY_LENGTH = 32

    def self.mainnet_version
      128
    end

    def self.testnet_version
      239
    end

    attr_accessor :public_key_compressed
    def public_key_compressed?
      @public_key_compressed
    end

    def key
      BTC::Key.new(private_key: self.private_key, public_key_compressed: @public_key_compressed, network: self.network)
    end

    def private_key
      @data
    end

    def public_address
      self.key.address(network: self.network)
    end

    def ==(other)
      return false if !other
                       self.data == other.data &&
                    self.version == other.version &&
      self.public_key_compressed == other.public_key_compressed
    end
    alias_method :eql?, :==

    # Usage:
    # * WIF.new(string: ...)
    # * WIF.new(private_key: ..., public_key_compressed: true|false, network: ...)
    # * WIF.new(key: ...)
    def initialize(string: nil,
                   data: nil,
                   network: nil,
                   _raw_data: nil,
                   private_key: nil,
                   key: nil,
                   public_key_compressed: nil)
      if key
        raise ArgumentError, "Key must contain private_key to be exported in WIF" if !key.private_key
        private_key = key.private_key
        if public_key_compressed == nil
          public_key_compressed = key.public_key_compressed
        end
        network ||= key.network
      end
      if string
        if data || private_key || key || (public_key_compressed != nil) || network
          raise ArgumentError, "Cannot specify individual attributes when decoding WIF from string"
        end
        _raw_data ||= Base58.data_from_base58check(string)
        if _raw_data.bytesize != (1 + KEY_LENGTH) && _raw_data.bytesize != (2 + KEY_LENGTH)
          raise FormatError, "Raw WIF data should have size #{1 + KEY_LENGTH}(+1), but it is #{_raw_data.bytesize} instead"
        end
        # compressed flag is simply one more byte appended to the string
        @base58check_string = string
        @data = _raw_data[1, KEY_LENGTH]
        @public_key_compressed = (_raw_data.bytesize == (2 + KEY_LENGTH))
        @version = _raw_data.bytes.first
        @network = nil
      elsif data ||= private_key
        if data.bytesize != KEY_LENGTH
          raise FormatError, "Failed to create WIF: data should have size #{KEY_LENGTH}, but it is #{data.bytesize} instead"
        end
        @base58check_string = nil
        @data = data
        @public_key_compressed = public_key_compressed
        if @public_key_compressed == nil
          @public_key_compressed = false # legacy default is uncompressed pubkey
        end
        @version = nil
        @network = network
      else
        raise ArgumentError, "Either data or string must be provided"
      end
    end

    def data_for_base58check_encoding
      data = BTC::Data.data_from_bytes([self.version]) + @data
      if @public_key_compressed
        data += BTC::Data.data_from_bytes([0x01])
      end
      return data
    end

    def inspect
      %{#<#{self.class}:#{to_s} privkey:#{BTC.to_hex(data)} (#{@public_key_compressed ? '' : 'un'}compressed pubkey)>}
    end

  end

  # For compatibility
  PrivateKeyAddress = WIF

end
