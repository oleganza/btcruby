# Implementation of BIP32 "Hierarchical Deterministic Wallets" (HD Wallets)
# https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki
#
# Keychain encapsulates either a pair of "extended" keys (private and public),
# or only a public extended key.
# "Extended key" means the key (private or public) is accompanied by an extra
# 256 bits of entropy called "chain code" and some metadata about its position
# in a tree of keys (depth, parent fingerprint, index).
#
# Keychain has two modes of operation:
#
# 1. "Normal derivation" which allows to derive public keys separately
#   from the private ones (internally i below 0x80000000).
#
# 2. "Hardened derivation" which derives only private keys (for i >= 0x80000000).
#
# Derivation can be treated as a single key or as a new branch of keychains.
# BIP43 and BIP44 propose a way for wallets to organize streams of keys using Keychain.
#
module BTC
  class Keychain

    MAX_INDEX = 0x7fffffff

    PUBLIC_MAINNET_VERSION  = 0x0488B21E # xpub
    PRIVATE_MAINNET_VERSION = 0x0488ADE4 # xprv
    PUBLIC_TESNET_VERSION   = 0x043587CF # tpub
    PRIVATE_TESTNET_VERSION = 0x04358394 # tprv

    # Instance of BTC::Key that is a "head" of this keychain.
    # If the keychain is public-only, key does not have a private component.
    attr_reader :key

    # 32-byte binary "chain code" string.
    attr_reader :chain_code

    # Base58Check-encoded extended public key.
    attr_reader :extended_public_key
    attr_reader :xpub

    # Base58Check-encoded extended private key.
    # Returns nil if it's a public-only keychain.
    attr_reader :extended_private_key
    attr_reader :xprv

    # 160-bit binary identifier (aka "hash") of the keychain (RIPEMD160(SHA256(pubkey)))
    attr_reader :identifier

    # Base58Check-encoded identifier.
    attr_reader :identifier_base58

    # Fingerprint of the keychain (integer).
    attr_reader :fingerprint

    # Fingerprint of the parent keychain (integer).
    # For master keychain it is always 0.
    attr_reader :parent_fingerprint

    # Index in the parent keychain (integer).
    # Returns 0 for master keychain.
    attr_reader :index

    # Depth in the hierarchy (integer).
    # Returns 0 for master keychain.
    attr_reader :depth

    # Network.mainnet or Network.testnet.
    # Default is BTC::Network.default (mainnet if not overriden).
    attr_accessor :network

    # Returns true if the keychain can derive private keys (opposite of #public?).
    def private?
      !!@private_key
    end

    # Returns true if the keychain can only derive public keys (opposite of #private?).
    def public?
      !@private_key
    end

    # Returns true if the keychain was derived via hardened derivation from its parent.
    # This means internally parameter i = 0x80000000 | self.index.
    # For the master keychain index is zero and hardened? returns false.
    def hardened?
      !!@hardened
    end

    def network
      @network
    end

    def network=(network)
      @network = network || Network.default
      @extended_public_key = nil
      @extended_private_key = nil
    end

    # Returns true if this keychain is intended for mainnet.
    def mainnet?
      network.mainnet?
    end

    # Returns true if this keychain is intended for testnet.
    def testnet?
      network.testnet?
    end

    def key
      @key ||= if @private_key
        BTC::Key.new(private_key: @private_key, public_key_compressed: true)
      else
        BTC::Key.new(public_key: @public_key)
      end
    end

    def to_s
      private? ? xprv : xpub
    end

    def xpub
      extended_public_key
    end

    def xprv
      extended_private_key
    end

    def extended_public_key
      @extended_public_key ||= begin
        prefix = _extended_key_prefix(mainnet? ? PUBLIC_MAINNET_VERSION : PUBLIC_TESNET_VERSION)
        BTC::Base58.base58check_from_data(prefix + @public_key)
      end
    end

    def extended_private_key
      @extended_private_key ||= begin
        return nil if !@private_key
        prefix = _extended_key_prefix(mainnet? ? PRIVATE_MAINNET_VERSION : PRIVATE_TESTNET_VERSION)
        BTC::Base58.base58check_from_data(prefix + "\x00" + @private_key)
      end
    end

    def identifier
      @identifier ||= BTC.hash160(@public_key)
    end

    def identifier_base58
      @identifier_base58 ||= BTC::Base58.base58check_from_data(self.identifier)
    end

    def fingerprint
      @fingerprint ||= BTC::WireFormat.read_uint32be(data:self.identifier).first
    end

    def ==(other)
      self.identifier == other.identifier &&
        self.private? == other.private? &&
        self.mainnet? == other.mainnet?
    end
    alias_method :eql?, :==

    def dup
      Keychain.new(extended_key: self.xprv || self.xpub)
    end

    # Returns a copy of the keychain stripped of the private key.
    # Equivalent to BTC::Keychain.new(xpub: keychain.xpub)
    def public_keychain
      self.class.new(_components: [
                     nil, # private_key
                     @public_key,
                     @chain_code,
                     @fingerprint,
                     @parent_fingerprint,
                     @index,
                     @depth,
                     @hardened,
                     @network])
    end

    # Instantiates Keychain with a binary seed or a base58-encoded extended public/private key.
    # Usage:
    # * Keychain.new(seed: ...[, network: ...])
    # * Keychain.new(extended_key: "xpub..." or "xprv...")
    # * Keychain.new(xpub: "xpub...")
    # * Keychain.new(xprv: "xprv...")
    def initialize(seed: nil,
                   extended_key: nil,
                   xpub: nil,
                   xprv: nil,
                   network: nil,
                   _components: nil # private API
                   )

      if seed
        init_with_seed(seed, network: network)
      elsif xkey = (xprv || xpub || extended_key)
        if network
          raise ArgumentError, "Cannot use network argument with extended key to initialize BTC::Keychain (network type is already encoded in the key)"
        end
        if [xprv, xpub, extended_key].compact.size != 1
          raise ArgumentError, "Only one of xpub/xprv/extended_key arguments could be used to initialize BTC::Keychain"
        end
        init_with_extended_key(xkey)
      elsif _components
        init_with_components(*_components)
      else
        raise ArgumentError, "Either seed or an extended " if !private_key && !public_key
      end
    end

    def init_with_seed(seed, network: nil)
      hmac = BTC.hmac_sha512(data: seed, key: "Bitcoin seed".encode(Encoding::ASCII))
      @private_key = hmac[0,32]
      @public_key = BTC::Key.new(private_key: @private_key, public_key_compressed: true).public_key
      @chain_code = hmac[32,32]
      @fingerprint = nil
      @parent_fingerprint = 0
      @index = 0
      @depth = 0
      @network = network || BTC::Network.default
    end
    private :init_with_seed


    def init_with_extended_key(xkey)
      xkeydata = BTC::Base58.data_from_base58check(xkey)

      if xkeydata.bytesize != 78
        raise BTCError, "Invalid extended key length: must be 78 bytes (received #{xkeydata.bytesize} bytes)"
      end

      version, _ = BTC::WireFormat.read_uint32be(data: xkeydata)

      bytes = xkeydata.bytes
      keyprefix = bytes[45]

      @network = Network.mainnet # not using Network.default because we set it explicitly based on xkey version.

      # Check if it's a private key
      if version == PRIVATE_MAINNET_VERSION || version == PRIVATE_TESTNET_VERSION

        # Should have 0x00-prefixed private key (1 + 32 bytes).
        if keyprefix != 0x00
          raise BTCError, "Extended private key must be padded with 0x00 byte (received #{keyprefix})"
        end

        @private_key = xkeydata[46, 32]
        @public_key = BTC::Key.new(private_key: @private_key, public_key_compressed: true).public_key
        if version == PRIVATE_TESTNET_VERSION
          @network = Network.testnet
        end

      elsif version == PUBLIC_MAINNET_VERSION || version == PUBLIC_TESNET_VERSION
        # Should have a 33-byte public key with non-zero first byte.
        if keyprefix == 0x00
          raise BTCError, "Extended public key must have non-zero first byte (received #{keyprefix})"
        end
        @public_key = xkeydata[45, 33]
        if version == PUBLIC_TESNET_VERSION
          @network = Network.testnet
        end
      else
        raise BTCError, "Unknown extended key version: 0x#{version.to_s(16).rjust(8, "0")}"
      end

      @depth = bytes[4] # 0 for master keychain, 1 for first level derived keychain etc.

      @parent_fingerprint, _ = BTC::WireFormat.read_uint32be(data: xkeydata, offset: 5)
      raise BTCError, "Cannot read uint32be parent_fingerprint" if !@parent_fingerprint

      @index, _ = BTC::WireFormat.read_uint32be(data: xkeydata, offset: 9)
      raise BTCError, "Cannot read uint32be index" if !@index

      @hardened = false
      if (0x80000000 & index) != 0
        @index = (~0x80000000) & @index
        @hardened = true
      end

      @chain_code = xkeydata[13, 32]
    end
    private :init_with_extended_key

    def init_with_components(private_key,
                             public_key,
                             chain_code,
                             fingerprint,
                             parent_fingerprint,
                             index,
                             depth,
                             hardened,
                             network)
      raise ArgumentError, "Either private or public key must be present" if !private_key && !public_key
      @private_key        = private_key
      @public_key         = public_key || BTC::Key.new(private_key: private_key, public_key_compressed: true).public_key
      @chain_code         = chain_code
      @fingerprint        = fingerprint
      @parent_fingerprint = parent_fingerprint
      @index              = index
      @depth              = depth
      @hardened           = hardened
      @network            = network
    end
    private :init_with_components

    def _extended_key_prefix(version)
      data = [version,
              @depth,
              @parent_fingerprint,
              @hardened ? (0x80000000 | @index) : @index
              ].pack(
              WireFormat::PACK_FORMAT_UINT32BE +
              WireFormat::PACK_FORMAT_UINT8 +
              WireFormat::PACK_FORMAT_UINT32BE +
              WireFormat::PACK_FORMAT_UINT32BE)

      data + @chain_code
    end
    private :_extended_key_prefix

    # Returns a derived keychain at a given index.
    # If hardened = true, uses hardened derivation (possible only when private
    # key is present; otherwise returns nil).
    # Index must be less of equal BTC::Keychain::MAX_INDEX, otherwise raises ArgumentError.
    # Raises BTCError for some indexes (when hashing leads to invalid EC points)
    # which is very rare (chance is below 2^-127), but must be expected.
    # In such case, simply use next index.
    # By default, a normal (non-hardened) derivation is used.
    def derived_keychain(index_or_path, hardened: nil)

      if index_or_path.is_a?(String)
        if hardened != nil
          raise ArgumentError, "Ambiguous use of `hardened` flag when deriving keychain with a string path"
        end
        return derived_keychain_with_path(index_or_path)
      end

      index = index_or_path

      raise ArgumentError, "Index must not be nil" if !index

      # As we use explicit "hardened" argument, do not allow higher bit set.
      if index < 0 || index > 0x7fffffff || (0x80000000 & index) != 0
        raise ArgumentError, "Index >= 0x80000000 is not valid. Use `hardened: true` argument instead."
      end

      if hardened && !@private_key
        # Not possible to derive hardened keychain without a private key.
        raise BTCError, "Not possible to derive a hardened keychain without a private key (index: #{index})."
      end

      private_key = nil
      public_key = nil
      chain_code = nil

      data = "".b

      if hardened
        data << "\x00" << @private_key
      else
        data << @public_key
      end

      data << BTC::WireFormat.encode_uint32be(hardened ? (0x80000000 | index) : index)

      digest = BTC.hmac_sha512(data: data, key: @chain_code)

      chain_code = digest[32,32]

      lib = BTC::OpenSSL
      lib.autorelease do |pool|

        factor = pool.new_bn(digest[0,32])
        n = lib.group_order

        if lib.BN_cmp(factor, n) >= 0
          raise BTCError, "Factor for index #{index} is greater than curve order."
        end

        if @private_key
          pk = pool.new_bn(@private_key)
          lib.BN_mod_add_quick(pk, pk, factor, n) # pk = (pk + factor) % n

          # Check for invalid derivation.

          if lib.BN_cmp(pk, pool.new_bn("\x00")) == 0
            raise BTCError, "Private key is zero for index #{index}."
          end

          private_key = lib.data_from_bn(pk, min_length: 32)
        else

          # Convert pubkey to a EC point
          pubkey_x = pool.new_bn(@public_key)
          pubkey_point = pool.new_ec_point
          lib.EC_POINT_bn2point(lib.group, pubkey_x, pubkey_point, pool.bn_ctx)

          # Compute point = pubkey + factor*G
          point = pool.new_ec_point
          # /** Computes r = generator * n + q * m
          #  *  \param  group  underlying EC_GROUP object
          #  *  \param  r      EC_POINT object for the result
          #  *  \param  n      BIGNUM with the multiplier for the group generator (optional)
          #  *  \param  q      EC_POINT object with the first factor of the second summand
          #  *  \param  m      BIGNUM with the second factor of the second summand
          #  *  \param  ctx    BN_CTX object (optional)
          #  *  \return 1 on success and 0 if an error occured
          #  */
          # int EC_POINT_mul(const EC_GROUP *group, EC_POINT *r, const BIGNUM *n, const EC_POINT *q, const BIGNUM *m, BN_CTX *ctx);
          lib.EC_POINT_mul(lib.group, point, factor, pubkey_point, pool.new_bn("\x01"), pool.bn_ctx)

          # Check for invalid derivation.
          if 1 == lib.EC_POINT_is_at_infinity(lib.group, point)
            raise BTCError, "Resulting point is at infinity for index #{index}."
          end

          lib.EC_POINT_point2bn(lib.group, point, BTC::OpenSSL::POINT_CONVERSION_COMPRESSED, pubkey_x, pool.bn_ctx)

          public_key = lib.data_from_bn(pubkey_x, required_length: 33)
        end
      end

      self.class.new(_components: [
                     private_key,
                     public_key,
                     chain_code,
                     nil,
                     self.fingerprint,
                     index,
                     @depth + 1,
                     !!hardened,
                     @network])
    end

    # Returns a derived BTC::Key from this keychain.
    # This is a convenient way to do keychain.derived_keychain(i).key
    # If the receiver contains a private key, child key will also contain a private key.
    # If the receiver contains only a public key, child key will only contain a public key.
    # (Or nil will be returned if hardened = true.)
    # By default, a normal (non-hardened) derivation is used.
    def derived_key(index_or_path, hardened: nil)
      self.derived_keychain(index_or_path, hardened: hardened).key
    end

    def derived_keychain_with_path(path)
      path.gsub(/^m\/?/, "").split("/").inject(self) do |keychain, segment|
        if segment =~ /^\d+\'?$/
          keychain.derived_keychain(segment.to_i, hardened: (segment[-1] == "'"))
        else
          raise ArgumentError, "Incorrect path format. Should be (\d+'?) separated by '/'."
        end
      end
    end

  end # Keychain
end # BTC
