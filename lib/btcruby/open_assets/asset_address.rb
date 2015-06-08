module BTC
  # Represents an Asset Address, where the assets can be sent.
  class AssetAddress < BTC::Address
    NAMESPACE = 0x13
    
    def self.mainnet_version
      NAMESPACE
    end

    def self.testnet_version
      NAMESPACE
    end

    attr_reader :bitcoin_address
    
    def initialize(string: nil, bitcoin_address: nil, _raw_data: nil)
      if string
        _raw_data ||= Base58.data_from_base58check(string)
        raise FormatError, "Too short AssetAddress" if _raw_data.bytesize < 2
        raise FormatError, "Invalid namespace for AssetAddress" if _raw_data.bytes[0] != NAMESPACE
        @bitcoin_address = Address.parse_raw_data(_raw_data[1..-1])
        @base58check_string = string
      elsif bitcoin_address
        @base58check_string = nil
        @bitcoin_address = BTC::Address.parse(bitcoin_address)
      else
        raise ArgumentError, "Either data or string must be provided"
      end
      # If someone accidentally supplied AssetAddress as a bitcoin address, 
      # simply unwrap the bitcoin address from it.
      while @bitcoin_address.is_a?(self.class)
        @bitcoin_address = @bitcoin_address.bitcoin_address
        @base58check_string = nil
      end
    end

    def network
      @bitcoin_address.network
    end

    def script
      @bitcoin_address.script
    end

    def data_for_base58check_encoding
      BTC::Data.data_from_bytes([NAMESPACE]) + @bitcoin_address.data_for_base58check_encoding
    end
  end
end
