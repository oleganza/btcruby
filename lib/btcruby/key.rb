# Key encapsulates EC public and private keypair (or only public part) on curve secp256k1.
# You can sign data and verify signatures.
# When instantiated with a public key, only signature verification is possible.
# When instantiated with a private key, all operations are available.
module BTC
  class Key

    # Flag specifying if the public key should be compressed.
    # Default is true.
    attr_reader :public_key_compressed

    # Returns a copy of BTC::Key instance with public_key_compressed == true
    attr_reader :compressed_key

    # Returns a copy of BTC::Key instance with public_key_compressed == false
    attr_reader :uncompressed_key

    # A binary string containing a private key. Returns nil if there is only public key.
    attr_reader :private_key

    # A binary string containing compressed or uncompressed public key (depends on public_key_compressed flag).
    attr_reader :public_key

    # A binary string containing a compressed public key.
    attr_reader :compressed_public_key

    # A binary string containing an uncompressed public key.
    attr_reader :uncompressed_public_key

    # A network to which this key belongs.
    # Affects how addresses and WIFs are formatted.
    # Default is BTC::Network.default (mainnet if not overriden).
    attr_accessor :network

    COMPRESSED_PUBKEY_LENGTH   = 33
    UNCOMPRESSED_PUBKEY_LENGTH = 65

    # Initializes a key with one of the given keys (public or private).
    # Usage:
    # * Key.new(private_key: ...[, public_key_compressed: ...][, network: ...])
    # * Key.new(public_key: ...[, network: ...])
    # * Key.new(wif: ...)
    def initialize(private_key: nil,
                   public_key: nil,
                   public_key_compressed: true,
                   wif: nil,
                   network: nil)

      @public_key_compressed = public_key_compressed
      @network = network || BTC::Network.default

      if private_key
        if !Key.validate_private_key_range(private_key)
          raise FormatError, "Private key is outside the valid range"
        end
        @private_key = private_key
      elsif public_key
        if !Key.valid_pubkey?(public_key)
          raise FormatError, "Invalid public key: #{public_key.inspect}"
        end
        @public_key_compressed = (self.class.length_for_pubkey(public_key) == COMPRESSED_PUBKEY_LENGTH)
        @public_key = public_key
      elsif wif
        wif = wif.is_a?(WIF) ? wif : Address.parse(wif)
        if !wif.is_a?(WIF)
          raise FormatError, "Invalid WIF string"
        end
        key = wif.key
        @private_key = key.private_key
        @public_key = key.public_key
        @public_key_compressed = key.public_key_compressed
        @network = wif.network
      else
        raise ArgumentError, "Must specify either private_key or public_key"
      end
    end

    # Creates a randomly-generated key pair.
    def self.random(public_key_compressed: true, network: nil)
      # Chances that we'll enter the loop are below 2^-127.
      privkey = BTC::Data.random_data(32)
      while !self.validate_private_key_range(privkey)
        privkey = BTC::Data.random_data(32)
      end
      return self.new(private_key: privkey,
                      public_key_compressed: public_key_compressed,
                      network: network)
    end


    # Accessors
    # ---------

    def network
      @network || BTC::Network.default
    end

    def compressed_key
      self.class.new(private_key: @private_key,
                     public_key: self.compressed_public_key,
                     public_key_compressed: true,
                     network: @network)
    end

    def uncompressed_key
      self.class.new(private_key: @private_key,
                     public_key: self.uncompressed_public_key,
                     public_key_compressed: false,
                     network: @network)
    end

    def public_key
      if !@public_key
        regenerate_key_pair
      end
      @public_key
    end

    def compressed_public_key
      BTC::OpenSSL.public_key_with_compression(self.public_key, true)
    end

    def uncompressed_public_key
      BTC::OpenSSL.public_key_with_compression(self.public_key, false)
    end

    # Returns a PublicKeyAddress instance that encodes a public key hash.
    def address(network: nil)
      PublicKeyAddress.new(public_key: self.public_key, network: network)
    end

    # Returns a WIF instance that encodes private key.
    def to_wif_object(network: nil)
      return nil if !self.private_key
      WIF.new(key: self, network: network)
    end

    # Returns private key encoded in WIF format (aka Sipa format).
    def to_wif(network: nil)
      return nil if !self.private_key
      self.to_wif_object(network: network).to_s
    end

    def dup
      self.class.new(
        private_key: @private_key,
        public_key: @public_key,
        public_key_compressed: @public_key_compressed,
        network: @network)
    end

    # Two keypairs are equal only when they are equally complete (both with or
    # without a private key), have matching keys and compression.
    def ==(other)
      self.public_key == other.public_key &&
      self.private_key == other.private_key
    end
    alias_method :eql?, :==

    # Multiplies a public key of the receiver with a given private key and
    # returns resulting curve point as BTC::Key object (pubkey only).
    # Pubkey compression flag is the same as on receiver.
    def diffie_hellman(key2)

      lib = BTC::OpenSSL
      lib.autorelease do |pool|

        pk = pool.new_bn(key2.private_key)
        n = lib.group_order

        # Convert pubkey to a EC point
        pubkey_x = pool.new_bn(self.compressed_public_key)
        pubkey_point = pool.new_ec_point
        lib.EC_POINT_bn2point(lib.group, pubkey_x, pubkey_point, pool.bn_ctx)

        # Compute point = pubkey*pk + 0*G
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
        lib.EC_POINT_mul(lib.group, point, nil, pubkey_point, pk, pool.bn_ctx)

        # Check for invalid derivation.
        if 1 == lib.EC_POINT_is_at_infinity(lib.group, point)
          raise MathError, "Resulting point is at infinity."
        end

        lib.EC_POINT_point2bn(
          lib.group,
          point,
          self.public_key_compressed ?
          BTC::OpenSSL::POINT_CONVERSION_COMPRESSED :
          BTC::OpenSSL::POINT_CONVERSION_UNCOMPRESSED,
          pubkey_x,
          pool.bn_ctx
        )

        result_pubkey = lib.data_from_bn(pubkey_x, required_length: 33)
        return Key.new(public_key: result_pubkey)
      end
    end



    # Signatures
    # ----------


    # Standard ECDSA signature for a given hash. Used by OP_CHECKSIG and friends.
    # Ensures canonical lower S value and makes a deterministic signature
    # (k = HMAC-SHA256(key: privkey, data: hash))
    def ecdsa_signature(hash, normalized: true)
      BTC::OpenSSL.ecdsa_signature(hash, @private_key, normalized: normalized)
    end

    # Returns true if ECDSA signature is valid for a given hash
    def verify_ecdsa_signature(signature, hash)
      BTC::OpenSSL.ecdsa_verify(signature, hash, self.public_key)
    end

    def self.normalized_signature(signature)
      BTC::OpenSSL.ecdsa_normalized_signature(signature)
    end

    # Validates and normalizes script signature to make it canonical.
    # Note: signature must have hashtype byte appended.
    # Returns nil if signature is invalid and cannot be normalized.
    # Returns original signature if it is canonical.
    # Returns normalized signature script if signature can be normalized.
    def self.validate_and_normalize_script_signature(data)
      raise ArgumentError, "Missing script signature data" if !data || data.size == 0
      if validate_script_signature(data)
        return data
      end
      data = BTC::Data.ensure_binary_encoding(data)
      normalized_sig = normalized_signature(data[0, data.size-1])
      return nil if !normalized_sig
      return normalized_sig + data[data.size-1, 1]
    end

    # Checks if this signature with appended script hash type is well-formed.
    # Logs detailed info using Diagnostics and returns true or false.
    # Set verify_lower_s:false when processing incoming blocks.
    def self.validate_script_signature(data, verify_lower_s: true)
      # See https://bitcointalk.org/index.php?topic=8392.msg127623#msg127623
      # A canonical signature exists of: <30> <total len> <02> <len R> <R> <02> <len S> <S> <hashtype>
      # Where R and S are not negative (their first byte has its highest bit not set), and not
      # excessively padded (do not start with a 0 byte, unless an otherwise negative number follows,
      # in which case a single 0 byte is necessary and even required).

      raise ArgumentError, "Missing script signature data" if !data

      data = BTC::Data.ensure_binary_encoding(data) # so we can use #[] on byte level.

      length = data.bytesize

      # Non-canonical signature: too short
      if length < 9
        Diagnostics.current.add_message("Non-canonical signature: too short.")
        return false
      end

      # Non-canonical signature: too long
      if length > 73
        Diagnostics.current.add_message("Non-canonical signature: too long.")
        return false
      end

      bytes = data.bytes

      hashtype = bytes[length - 1] & (~(SIGHASH_ANYONECANPAY))

      if hashtype < SIGHASH_ALL || hashtype > SIGHASH_SINGLE
        Diagnostics.current.add_message("Non-canonical signature: unknown hashtype byte.")
        return false
      end

      if bytes[0] != 0x30
        Diagnostics.current.add_message("Non-canonical signature: wrong type.")
        return false
      end

      if bytes[1] != length-3
        Diagnostics.current.add_message("Non-canonical signature: wrong length marker.")
        return false
      end

      lenR = bytes[3]

      if (5 + lenR) >= length
        Diagnostics.current.add_message("Non-canonical signature: S length misplaced.")
        return false
      end

      lenS = bytes[5 + lenR]

      if (lenR + lenS + 7) != length
        Diagnostics.current.add_message("Non-canonical signature: R+S length mismatch")
        return false
      end

      bufR = bytes[4, lenR]
      if bytes[4 - 2] != 0x02
        Diagnostics.current.add_message("Non-canonical signature: R value type mismatch")
        return false
      end

      if lenR == 0
        Diagnostics.current.add_message("Non-canonical signature: R length is zero")
        return false
      end

      if bufR[0] & 0x80 != 0
        Diagnostics.current.add_message("Non-canonical signature: R value negative")
        return false
      end

      if lenR > 1 && (bufR[0] == 0x00) && ((bufR[1] & 0x80) == 0)
        Diagnostics.current.add_message("Non-canonical signature: R value excessively padded")
        return false
      end

      bufS = bytes[6 + lenR, lenS]
      s = data[6 + lenR, lenS]
      if bytes[6 + lenR - 2] != 0x02
        Diagnostics.current.add_message("Non-canonical signature: S value type mismatch")
        return false
      end

      if lenS == 0
        Diagnostics.current.add_message("Non-canonical signature: S length is zero")
        return false
      end

      if bufS[0] & 0x80 != 0
        return false
        Diagnostics.current.add_message("Non-canonical signature: S value is negative")
      end

      if lenS > 1 && (bufS[0] == 0x00) && ((bufS[1] & 0x80) == 0)
        Diagnostics.current.add_message("Non-canonical signature: S value excessively padded")
        return false
      end

      if verify_lower_s
        if !self_validate_signature_element(s, check_half: true)
          Diagnostics.current.add_message("Non-canonical signature: S value is unnecessarily high")
          return false
        end
      end

      return true
    end

    # Zero-filled 32-byte buffer
    KEY_ZERO = "\x00"*32

    # Order of secp256k1's generator minus 1.
    KEY_MAX_MOD_ORDER =("\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF" +
                        "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFE" +
                        "\xBA\xAE\xDC\xE6\xAF\x48\xA0\x3B" +
                        "\xBF\xD2\x5E\x8C\xD0\x36\x41\x40").b.freeze

    # Half of the order of secp256k1's generator minus 1.
    KEY_MAX_MOD_HALF_ORDER =("\x7F\xFF\xFF\xFF\xFF\xFF\xFF\xFF" +
                             "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF" +
                             "\x5D\x57\x6E\x73\x57\xA4\x50\x1D" +
                             "\xDF\xE9\x2F\x46\x68\x1B\x20\xA0").b.freeze

    # Private helper to compare two big numbers in big-endian notation.
    # Higher byte has higher value, but strings can be of different length.
    def self.compare_big_endian(s1, s2)
      s1 = BTC::Data.ensure_binary_encoding(s1)
      s2 = BTC::Data.ensure_binary_encoding(s2)

      if s1.bytesize < s2.bytesize
        s1 = "\x00"*(s2.bytesize - s1.bytesize) + s1
      end

      if s2.bytesize < s1.bytesize
        s2 = "\x00"*(s1.bytesize - s2.bytesize) + s2
      end

      s1 <=> s2
    end

    # Private helper to validate portion of a signate. Follows style of bitcoind.
    def self.self_validate_signature_element(data, check_half: false)
      return self.compare_big_endian(data, KEY_ZERO) > 0 &&
             self.compare_big_endian(data, check_half ? KEY_MAX_MOD_HALF_ORDER : KEY_MAX_MOD_ORDER) <= 0
    end

    # Returns true if data representing a private key is within a valid range.
    def self.validate_private_key_range(private_key)
        return self.compare_big_endian(private_key, KEY_ZERO) > 0 &&
               self.compare_big_endian(private_key, KEY_MAX_MOD_ORDER) <= 0
    end

    # Checks if this public key is valid and well-formed.
    # Logs detailed info using Diagnostics and returns true or false.
    def self.validate_public_key(data)
      raise ArgumentError, "Missing public key" if !data

      length = data.bytesize

      # Non-canonical public key: too short
      if length < 33
        Diagnostics.current.add_message("Non-canonical public key: too short.")
        return false
      end

      bytes = data.bytes

      if bytes[0] == 0x04
        # Length of an uncompressed key must be 65 bytes.
        return true if length == 65
        Diagnostics.current.add_message("Non-canonical public key: length of uncompressed key must be 65 bytes.")
        return false
      elsif bytes[0] == 0x02 || bytes[0] == 0x03
        # Length of compressed key must be 33 bytes.
        return true if length == 33
        Diagnostics.current.add_message("Non-canonical public key: length of compressed key must be 33 bytes.")
        return false
      end

      # Unknown public key format.
      Diagnostics.current.add_message("Unknown non-canonical public key.")
      return false
    end

    # Non-standard "compact" signature used for Bitcoin signed messages.
    # It features fixed length and allows efficient extraction of a public key from it.
    def compact_signature(hash)
      raise BTCError, "Not implemented"
    end

    # Returns true if compact signature is valid for a given hash
    def verify_compact_signature(signature, hash)
      raise BTCError, "Not implemented"
    end

    # Compact signature for a given message. Prepends it with standard prefix
    # "\x18Bitcoin Signed Message:\n" and encodes message in wire format.
    def message_signature(message)
      raise BTCError, "Not implemented"
    end

    def verify_message_signature(signature, message)
      raise BTCError, "Not implemented"
    end




    protected


    # Helpers

    def regenerate_key_pair
      if @private_key
        privkey, pubkey = BTC::OpenSSL.regenerate_keypair(@private_key, public_key_compressed: @public_key_compressed)
        if privkey && pubkey
          @private_key = privkey
          @public_key = pubkey
        end
      end
      self
    end

    def self.length_for_pubkey(data)
      return 0 if data.bytesize == 0
      header = data.bytes[0];
      if header == 2 || header == 3
        return COMPRESSED_PUBKEY_LENGTH
      end
      if header == 4 || header == 6 || header == 7
        return UNCOMPRESSED_PUBKEY_LENGTH
      end
      return 0
    end

    def self.valid_pubkey?(data)
      raise ArgumentError, "Pubkey is missing" if !data
      length = data.bytesize
      return length > 0 && self.length_for_pubkey(data) == length
    end

  end
end
