# Addresses are Base58-encoded pieces of data representing various objects:
#
# 1. Public key hash address. Example: 19FGfswVqxNubJbh1NW8A4t51T9x9RDVWQ.
# 2. Private key for uncompressed public key (WIF).
#    Example: 5KQntKuhYWSRXNqp2yhdXzjekYAR7US3MT1715Mbv5CyUKV6hVe.
# 3. Private key for compressed public key (WIF).
#    Example: L3p8oAcQTtuokSCRHQ7i4MhjWc9zornvpJLfmg62sYpLRJF9woSu.
# 4. Script hash address (P2SH). Example: 3NukJ6fYZJ5Kk8bPjycAnruZkE5Q7UW7i8.
#
# To differentiate between testnet and mainnet, use `network` accessor or `mainnet?`/`testnet?` methods.
#
# To check if the instance of the class is available for
# mainnet or testnet, use mainnet? and testnet? methods respectively.
#
# Usage:
# 1. When receiving an address in Base58 format, convert it to a proper type by doing:
#
#      address = BTC::Address.parse("19FGfswVqxNubJbh1NW8A4t51T9x9RDVWQ")
#
# 2. To create an address, use appropriate type and call with_data(binary_data):
#
#      address = BTC::PublicKeyAddress.new(hash: hash)
#
# 3. To convert address to its Base68Check format call to_s:
#
#      string = address.to_s
#
module BTC
  class Address

    # Decodes address from a Base58Check-encoded string
    def self.parse(string_or_address)
      raise ArgumentError, "Argument is missing" if !string_or_address
      if string_or_address.is_a?(self)
        return string_or_address
      elsif string_or_address.is_a?(Address)
        raise ArgumentError, "Argument must be an instance of #{self}, not #{string_or_address.class}."
      end
      string = string_or_address
      raise ArgumentError, "String is expected" if !string.is_a?(String)
      raw_data = Base58.data_from_base58check(string)
      result = parse_raw_data(raw_data, string)
      if !result.is_a?(self)
        raise ArgumentError, "Argument must be an instance of #{self}, not #{result.class}."
      end
      result
    end

    # Internal method to parse address from raw binary data.
    def self.parse_raw_data(raw_data, _string = nil)
      raise ArgumentError, "Raw data is missing" if !raw_data
      if raw_data.bytesize < 2 # should contain at least a version byte and some content
        raise FormatError, "Failed to decode BTC::Address: raw data is too short"
      end
      version = raw_data.bytes.first
      address_class = version_to_class_dictionary[version]
      if !address_class
        raise FormatError, "Failed to decode BTC::Address: unknown version #{version}"
      end
      return address_class.new(string: _string, _raw_data: raw_data)
    end

    def network
      @network ||= if !@version
        BTC::Network.default
      elsif @version == self.class.mainnet_version
        BTC::Network.mainnet
      else
        BTC::Network.testnet
      end
    end

    def version
      @version ||= if self.network.mainnet?
        self.class.mainnet_version
      else
        self.class.testnet_version
      end
    end

    # Returns binary contents of the address (without version byte and checksum).
    def data
      @data
    end

    # Returns a public version of the address. For public addresses (P2PKH and P2SH) returns self.
    def public_address
      self
    end

    # Two instances are equal when they have the same contents and versions.
    def ==(other)
      return false if !other
      self.data == other.data && self.version == other.version
    end
    alias_method :eql?, :==

    # Returns Base58Check representation of an address.
    def to_s
      @base58check_string ||= Base58.base58check_from_data(self.data_for_base58check_encoding)
    end

    # Whether this address is usable on mainnet.
    def mainnet?
      self.network.mainnet?
    end

    # Whether this address is usable on testnet.
    def testnet?
      self.network.testnet?
    end

    # Whether this address is pay-to-public-key-hash (classic address which is a hash of a single public key).
    def p2pkh?
      false
    end

    # Whether this address is pay-to-script-hash.
    def p2sh?
      false
    end

    def inspect
      %{#<#{self.class}:#{to_s}>}
    end

    protected

    # Overriden in subclasses to provide concrete version
    def self.mainnet_version
      raise Exception, "Override mainnet_version in your subclass"
    end

    def self.testnet_version
      raise Exception, "Override testnet_version in your subclass"
    end

    # To override in subclasses
    def data_for_base58check_encoding
      raise Exception, "Override data_for_base58check_encoding in #{self.class} to return complete data to be base58-encoded."
    end

    private

    def self.version_to_class_dictionary
      @version_to_class_dictionary ||= [
        PublicKeyAddress,
        ScriptHashAddress,
        WIF,
        AssetID,
        AssetAddress
      ].inject({}) do |dict, cls|
        dict[cls.mainnet_version] = cls
        dict[cls.testnet_version] = cls
        dict
      end
    end
  end

  class BitcoinPaymentAddress < Address
  end

  # Base class for P2SH and P2PKH addresses
  class Hash160Address < BitcoinPaymentAddress

    HASH160_LENGTH = 20

    def initialize(string: nil, hash: nil, network: nil, _raw_data: nil)
      if string || _raw_data
        _raw_data ||= Base58.data_from_base58check(string)
        if _raw_data.bytesize != (1 + HASH160_LENGTH)
          raise FormatError, "Raw data should have length #{1 + HASH160_LENGTH}, but it is #{_raw_data.bytesize} instead"
        end
        @base58check_string = string
        @data = _raw_data[1, HASH160_LENGTH]
        @version = _raw_data.bytes.first
        @network = nil
      elsif hash
        if hash.bytesize != HASH160_LENGTH
          raise FormatError, "Data should have length #{HASH160_LENGTH}, but it is #{hash.bytesize} instead"
        end
        @base58check_string = nil
        @data = hash
        @version = nil
        @network = network
      else
        raise ArgumentError, "Either data or string must be provided"
      end
    end

    def hash
      @data
    end

    def data_for_base58check_encoding
      BTC::Data.data_from_bytes([self.version]) + @data
    end
  end



  # Standard pulic key (P2PKH) address (e.g. 19FGfswVqxNubJbh1NW8A4t51T9x9RDVWQ)
  class PublicKeyAddress < Hash160Address

    def self.mainnet_version
      0
    end

    def self.testnet_version
      111
    end

    def p2pkh?
      true
    end

    # Instantiates address with a BTC::Key or a binary public key.
    def initialize(string: nil, hash: nil, network: nil, _raw_data: nil, public_key: nil, key: nil)
      if key
        super(hash: BTC.hash160(key.public_key), network: key.network || network)
      elsif public_key
        super(hash: BTC.hash160(public_key), network: network)
      else
        super(string: string, hash: hash, network: network, _raw_data: _raw_data)
      end
    end

    # Returns BTC::Script with data 'OP_DUP OP_HASH160 <hash> OP_EQUALVERIFY OP_CHECKSIG'
    def script
      raise ArgumentError, "BTC::PublicKeyAddress: invalid data length (must be 20 bytes)" if self.data.bytesize != 20
      BTC::Script.new << OP_DUP << OP_HASH160 << self.data << OP_EQUALVERIFY << OP_CHECKSIG
    end
  end


  # P2SH address (e.g. 3NukJ6fYZJ5Kk8bPjycAnruZkE5Q7UW7i8)
  class ScriptHashAddress < Hash160Address

    def self.mainnet_version
      5
    end

    def self.testnet_version
      196
    end

    def p2sh?
      true
    end

    # Instantiates address with a given redeem script.
    def initialize(string: nil, hash: nil, network: nil, _raw_data: nil, redeem_script: nil)
      if redeem_script
        super(hash: BTC.hash160(redeem_script.data), network: network)
      else
        super(string: string, hash: hash, network: network, _raw_data: _raw_data)
      end
    end

    # Returns BTC::Script with data 'OP_HASH160 <hash> OP_EQUAL'
    def script
      raise ArgumentError, "BTC::ScriptHashAddress: invalid data length (must be 20 bytes)" if self.data.bytesize != 20
      BTC::Script.new << OP_HASH160 << self.data << OP_EQUAL
    end
  end
end
