module BTC
  module StringExtensions

    # Converts binary string as a private key to a WIF Base58 format.
    def to_wif(network: nil, public_key_compressed: nil)
      BTC::WIF.new(private_key: self, network: network, public_key_compressed: public_key_compressed).to_s
    end

    # Decodes string in WIF format into a binary private key (32 bytes)
    def from_wif
      addr = BTC::WIF.new(string: self)
      addr ? addr.private_key : nil
    end

    # Converts binary data into hex string
    def to_hex
      BTC::Data.hex_from_data(self)
    end

    # Converts hex string into a binary data
    def from_hex
      BTC::Data.data_from_hex(self)
    end

    # Various hash functions
    def hash256
      BTC.hash256(self)
    end

    def hash160
      BTC.hash160(self)
    end

    def sha1
      BTC.sha1(self)
    end

    def ripemd160
      BTC.ripemd160(self)
    end

    def sha256
      BTC.sha256(self)
    end

    def sha512
      BTC.sha512(self)
    end

    def hmac_sha256(data: nil, key: nil)
      raise ArgumentError, "Either data or key must be specified" if !data && !key
      BTC.hmac_sha256(data: data || self, key: key || self)
    end

    def hmac_sha512(data: nil, key: nil)
      raise ArgumentError, "Either data or key must be specified" if !data && !key
      BTC.hmac_sha512(data: data || self, key: key || self)
    end

  end
end

class ::String
  include BTC::StringExtensions
end