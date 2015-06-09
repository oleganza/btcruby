require 'ffi'

# This is a collection of binding to OpenSSL that are missing in standard library in Ruby 2.0.
# You need an 'ffi' gem to make it work.
module BTC
  module OpenSSL
    include ::FFI::Library
    extend self

    if FFI::Platform.windows?
      ffi_lib 'libeay32', 'ssleay32'
    else
      ffi_lib 'ssl'
    end

    NID_secp256k1 = 714

    POINT_CONVERSION_COMPRESSED   = 0x02
    POINT_CONVERSION_UNCOMPRESSED = 0x04

    attach_function :SSL_library_init,         [], :int
    attach_function :ERR_load_crypto_strings,  [], :void
    attach_function :SSL_load_error_strings,   [], :void
    attach_function :RAND_poll,                [], :int

    attach_function :BN_CTX_free,              [:pointer],                                         :int
    attach_function :BN_CTX_new,               [],                                                 :pointer
    attach_function :BN_new,                   [],                                                 :pointer
    attach_function :BN_free,                  [:pointer],                                         :int
    attach_function :BN_copy,                  [:pointer, :pointer],                               :pointer
    attach_function :BN_dup,                   [:pointer],                                         :pointer
    attach_function :BN_bin2bn,                [:pointer, :int,     :pointer],                     :pointer
    attach_function :BN_bn2bin,                [:pointer, :pointer],                               :void
    attach_function :BN_num_bits,              [:pointer],                                         :int
    attach_function :BN_cmp,                   [:pointer, :pointer],                               :int
    attach_function :BN_set_word,              [:pointer, :int],                                   :int
    attach_function :BN_add,                   [:pointer, :pointer, :pointer],                     :int
    attach_function :BN_sub,                   [:pointer, :pointer, :pointer],                     :int
    attach_function :BN_div,                   [:pointer, :pointer, :pointer, :pointer, :pointer], :int
    attach_function :BN_mod_inverse,           [:pointer, :pointer, :pointer, :pointer],           :pointer
    attach_function :BN_mod_mul,               [:pointer, :pointer, :pointer, :pointer, :pointer], :int
    attach_function :BN_mod_add,               [:pointer, :pointer, :pointer, :pointer, :pointer], :int
    attach_function :BN_mod_add_quick,         [:pointer, :pointer, :pointer, :pointer],           :int
    attach_function :BN_mod_sub,               [:pointer, :pointer, :pointer, :pointer, :pointer], :int
    attach_function :BN_mul_word,              [:pointer, :int],                                   :int
    attach_function :BN_rshift,                [:pointer, :pointer, :int],                         :int
    attach_function :BN_rshift1,               [:pointer, :pointer],                               :int

    attach_function :EC_GROUP_new_by_curve_name, [:int],                                           :pointer
    attach_function :EC_GROUP_free,            [:pointer],                                         :void
    attach_function :EC_GROUP_get_curve_GFp,   [:pointer, :pointer, :pointer, :pointer, :pointer], :int
    attach_function :EC_GROUP_get_degree,      [:pointer],                                         :int
    attach_function :EC_GROUP_get_order,       [:pointer, :pointer, :pointer],                     :int
    attach_function :EC_GROUP_get0_generator,  [:pointer],                                         :pointer

    attach_function :EC_KEY_new_by_curve_name, [:int],                                             :pointer
    attach_function :EC_KEY_free,              [:pointer],                                         :void
    attach_function :EC_KEY_get0_group,        [:pointer],                                         :pointer
    attach_function :EC_KEY_get0_private_key,  [:pointer],                                         :pointer
    attach_function :EC_KEY_set_conv_form,     [:pointer, :int],                                   :void
    attach_function :EC_KEY_set_private_key,   [:pointer, :pointer],                               :int
    attach_function :EC_KEY_set_public_key,    [:pointer, :pointer],                               :int

    attach_function :d2i_ECPrivateKey,         [:pointer, :pointer, :long],                        :pointer
    attach_function :i2d_ECPrivateKey,         [:pointer, :pointer],                               :int
    attach_function :o2i_ECPublicKey,          [:pointer, :pointer, :long],                        :pointer
    attach_function :i2o_ECPublicKey,          [:pointer, :pointer],                               :uint

    attach_function :EC_POINT_new,             [:pointer],                                         :pointer
    attach_function :EC_POINT_free,            [:pointer],                                         :int
    attach_function :EC_POINT_is_at_infinity,  [:pointer, :pointer],                               :int
    attach_function :EC_POINT_mul,             [:pointer, :pointer, :pointer, :pointer, :pointer, :pointer], :int
    attach_function :EC_POINT_set_compressed_coordinates_GFp, [:pointer, :pointer, :pointer, :int, :pointer], :int
    attach_function :EC_POINT_copy,            [:pointer, :pointer],                               :int
    attach_function :EC_POINT_get_affine_coordinates_GFp, [:pointer, :pointer, :pointer, :pointer, :pointer], :int
    attach_function :EC_POINT_point2bn,        [:pointer, :pointer, :int, :pointer, :pointer],     :pointer
    attach_function :EC_POINT_bn2point,        [:pointer, :pointer, :pointer, :pointer],           :pointer

    attach_function :ECDSA_SIG_new,            [],                                                 :pointer
    attach_function :ECDSA_SIG_free,           [:pointer],                                         :void
    attach_function :ECDSA_do_sign,            [:pointer, :uint, :pointer],                        :pointer
    attach_function :ECDSA_verify,             [:int, :pointer, :int, :pointer, :int, :pointer],   :int

    attach_function :i2d_ECDSA_SIG,            [:pointer, :pointer],                               :int
    attach_function :d2i_ECDSA_SIG,            [:pointer, :pointer, :long],                        :pointer

    def BN_num_bytes(a) # in openssl this is defined by a macro
      (BN_num_bits(a)+7)/8
    end

    def prepare_if_needed
      if !@prepared_openssl
        SSL_library_init()
        ERR_load_crypto_strings()
        SSL_load_error_strings()
        RAND_poll()
        @prepared_openssl = true
      end
    end

    def group
      @group ||= EC_GROUP_new_by_curve_name(NID_secp256k1)
    end

    def group_order
      @group_order ||= begin
        n = BN_new()
        bn_ctx = BN_CTX_new()
        EC_GROUP_get_order(self.group, n, bn_ctx)
        BN_CTX_free(bn_ctx)
        n
      end
    end

    def group_half_order
      @group_half_order ||= begin
        halforder = BN_new()
        BN_rshift1(halforder, self.group_order)
        halforder
      end
    end

    # Creates autorelease pool from which various objects can be created.
    # When block returns, pool deallocates all created objects.
    # Available methods on pool instance:
    # - ec_key       - last EC_KEY (created lazily if needed)
    # - group        - group of the ec_key
    # - bn_ctx       - lazily created single instance of BN_CTX
    # - new_ec_key   - creates new instance of EC_KEY
    # - new_bn       - creates new instance of BIGNUM
    # - new_ec_point - creates new instance of EC_POINT
    def autorelease(&block) # {|pool|  }
      prepare_if_needed
      result = nil
      begin
        pool = AutoreleasePool.new
        result = yield(pool)
      ensure
        pool.drain
      end
      result
    end

    def public_key_with_compression(pubkey, compressed)
      raise ArgumentError, "Public key is missing" if !pubkey

      autorelease do |pool|

        eckey = pool.new_ec_key

        # 1. Load EC_KEY with pubkey binary data.
        buf = FFI::MemoryPointer.from_string(pubkey)
        eckey = o2i_ECPublicKey(pointer_to_pointer(eckey), pointer_to_pointer(buf), buf.size-1)
        if eckey.null?
          raise BTCError, "OpenSSL failed to create EC_KEY with public key: #{BTC.to_hex(pubkey).inspect}"
        end

        # 2. Extract re-compressed pubkey from EC_KEY
        EC_KEY_set_conv_form(eckey, compressed ? POINT_CONVERSION_COMPRESSED : POINT_CONVERSION_UNCOMPRESSED);

        length = i2o_ECPublicKey(eckey, nil)
        buf = FFI::MemoryPointer.new(:uint8, length)
        if i2o_ECPublicKey(eckey, pointer_to_pointer(buf)) == length
          public_key = buf.read_string(length)
        else
          raise BTCError, "OpenSSL failed to regenerate a public key."
        end

        public_key
      end
    end

    # Returns a pair of private key, public key
    def regenerate_keypair(private_key, public_key_compressed: false)

      autorelease do |pool|

        eckey = pool.new_ec_key

        priv_bn = pool.new_bn(private_key)

        pub_key = pool.new_ec_point
        EC_POINT_mul(self.group, pub_key, priv_bn, nil, nil, pool.bn_ctx)
        EC_KEY_set_private_key(eckey, priv_bn)
        EC_KEY_set_public_key(eckey, pub_key)

        length = i2d_ECPrivateKey(eckey, nil)
        buf = FFI::MemoryPointer.new(:uint8, length)
        if i2d_ECPrivateKey(eckey, pointer_to_pointer(buf)) == length
          # We have a full DER representation of private key, it contains a length
          # of a private key at offset 8 and private key at offset 9.
          size = buf.get_array_of_uint8(8, 1)[0]
          private_key2 = buf.get_array_of_uint8(9, size).pack("C*").rjust(32, "\x00")
        else
          raise BTCError, "OpenSSL failed to convert private key to DER format"
        end

        if private_key2 != private_key
          raise BTCError, "OpenSSL somehow regenerated a wrong private key."
        end

        EC_KEY_set_conv_form(eckey, public_key_compressed ? POINT_CONVERSION_COMPRESSED : POINT_CONVERSION_UNCOMPRESSED);

        length = i2o_ECPublicKey(eckey, nil)
        buf = FFI::MemoryPointer.new(:uint8, length)
        if i2o_ECPublicKey(eckey, pointer_to_pointer(buf)) == length
          public_key = buf.read_string(length)
        else
          raise BTCError, "OpenSSL failed to regenerate a public key."
        end

        [ private_key2, public_key ]
      end
    end

    # Returns k value computed deterministically from message hash and privkey.
    # See https://tools.ietf.org/html/rfc6979
    def rfc6979_ecdsa_nonce(hash, privkey)
      raise ArgumentError, "Hash must be 32 bytes long" if hash.bytesize != 32
      raise ArgumentError, "Private key must be 32 bytes long" if privkey.bytesize != 32

      autorelease do |pool|
        order = self.group_order

        # Step 3.2.a. hash = H(message). Already performed by the caller.

        # Step 3.2.b. V = 0x01 0x01 0x01 ... 0x01 (32 bytes equal 0x01)
        v = "\x01".b*32

        # Step 3.2.c. K = 0x00 0x00 0x00 ... 0x00 (32 bytes equal 0x00)
        k = "\x00".b*32

        # Step 3.2.d. K = HMAC-SHA256(key: K, data: V || 0x00 || int2octets(privkey) || bits2octets(hash))
        h1 = pool.new_bn(hash)
        BN_div(nil, h1, h1, order, pool.bn_ctx) # h1 = h1 % order
        h1data = data_from_bn(h1, min_length: 32)
        k = BTC.hmac_sha256(key: k, data: v + "\x00".b + privkey + h1data)

        # Step 3.2.e. V = HMAC-SHA256(key: K, data: V)
        v = BTC.hmac_sha256(key: k, data: v)

        # Step 3.2.f. K = HMAC-SHA256(key: K, data: V || 0x01 || int2octets(privkey) || bits2octets(hash))
        k = BTC.hmac_sha256(key: k, data: v + "\x01".b + privkey + h1data)

        # Step 3.2.g. V = HMAC-SHA256(key: K, data: V)
        v = BTC.hmac_sha256(key: k, data: v)

        # Step 3.2.h.
        zero32 = "\x00".b*32
        10000.times do
          t = BTC.hmac_sha256(key: k, data: v)
          tn = pool.new_bn(t)
          if BN_cmp(tn, order) < 0
            nonce = data_from_bn(tn, min_length: 32)
            if nonce != zero32
              return nonce
            end
          end
          # Note: the probability of not succeeding at the first try is about 2^-127.
          k = BTC.hmac_sha256(key: k, data: v + zero32)
          v = BTC.hmac_sha256(key: k, data: v)
        end
        # we generated 10000 numbers, none of them is good -> fail.
        raise "Cannot find any good ECDSA nonce after 10000 iterations of RFC6979."
      end
    end

    # Computes a deterministic ECDSA signature with canonical (lowest) S value.
    # Nonce k is equal to HMAC-SHA256(data: hash, key: privkey)
    def ecdsa_signature(hash, privkey, normalized: true)
      raise ArgumentError, "Hash is missing" if !hash
      raise ArgumentError, "Cannot make a ECDSA signature without the private key" if !privkey

      # ECDSA signature is a pair of numbers: (Kx, s)
      # Where Kx = x coordinate of k*G mod n (n is the order of secp256k1).
      # And s = (k^-1)*(h + Kx*privkey).
      # By default, k is chosen randomly on interval [0, n - 1].
      # But this makes signatures harder to test and allows faulty or
      # backdoored RNGs to leak private keys from ECDSA signatures.
      # To avoid these issues, we'll generate k = Hash256(hash || privatekey)
      # and make all computations by hand.

      autorelease do |pool|

        # Order of our curve
        n = self.group_order
        halfn = self.group_half_order

        # Generate k deterministically from private key and message using HMAC-SHA256
        # This is an important point #1.
        kdata = rfc6979_ecdsa_nonce(hash, privkey)
        k = pool.new_bn(kdata)

        # Enforce k within group order: k = k % n
        BN_div(nil, k, k, n, pool.bn_ctx)

        # Compute K = k*G
        #(can't use K variable name because Ruby does not allow
        # constant assignment in methods)
        kG = pool.new_ec_point
        EC_POINT_mul(self.group, kG, k, nil, nil, pool.bn_ctx)

        # Compute r = K.x. This is first half of the signature.
        r = pool.new_bn
        EC_POINT_get_affine_coordinates_GFp(self.group, kG, r, nil, pool.bn_ctx)

        # Compute s = (k^-1)*(h + r*privkey).
        h = pool.new_bn(hash)
        p = pool.new_bn(privkey)
        tmp = pool.new_bn
        s = pool.new_bn
        BN_mod_mul(tmp, r, p, n, pool.bn_ctx) # tmp = r*privkey
        BN_mod_add_quick(s, tmp, h, n)        # s = h + tmp = h + r*privkey
        BN_mod_inverse(k, k, n, pool.bn_ctx)  # k' = k^-1
        BN_mod_mul(s, s, k, n, pool.bn_ctx)   # s = k'*(h + r*privkey)

        # Enforce low S values, by negating the value (modulo the order) if above order/2.
        # This is an important point #2. Not doing that would yield (sometimes)
        # non-canonical signatures that will be rejected by many relaying nodes.
        if normalized
          if BN_cmp(s, halfn) > 0
            BN_sub(s, n, s)
          end
        end

        # Fill in ECDSA_SIG structure so we can convert it into a proper DER format.
        sig = ECDSA_SIG.new
        sig[:r] = r
        sig[:s] = s

        # Encode signature in DER format.

        sig_size = 72 # typical size of a signature (when both numbers are 33 bytes).

        # allocate a bit more memory just in case (cargo cult)
        buffer = FFI::MemoryPointer.new(:uint8, sig_size + 16)
        sig_size = i2d_ECDSA_SIG(sig.pointer, pointer_to_pointer(buffer))

        # read actual number of bytes composed by OpenSSL
        signature = buffer.read_string(sig_size)
        signature
      end
    end

    # Normalizes S value of the signature and returns normalized signature.
    # Returns nil if signature is completely invalid.
    def ecdsa_normalized_signature(signature)
      raise ArgumentError, "Signature is missing" if !signature

      autorelease do |pool|

        # Order of our curve
        n = self.group_order
        halfn = self.group_half_order

        # ECDSA_SIG *psig = NULL;
        # d2i_ECDSA_SIG(&psig, &input, vchSig.size());
        buf = FFI::MemoryPointer.from_string(signature)
        psig = d2i_ECDSA_SIG(nil, pointer_to_pointer(buf), buf.size-1)
        if psig.null?
          raise BTCError, "OpenSSL failed to read ECDSA signature with DER: #{BTC.to_hex(signature).inspect}"
        end

        sig = ECDSA_SIG.new(psig) # read sig from its pointer
        s = sig[:s]

        # Enforce low S values, by negating the value (modulo the order) if above order/2.
        if BN_cmp(s, halfn) > 0
          BN_sub(s, n, s)
        end

        # Note: we'll place new s value back to s bignum,
        # so we don't need another sig structure.

        # Encode signature in DER format.
        sig_size = 72 # typical size of a signature (when both numbers are 33 bytes).

        # allocate a bit more memory just in case (cargo cult)
        buffer = FFI::MemoryPointer.new(:uint8, sig_size + 16)
        sig_size = i2d_ECDSA_SIG(sig.pointer, pointer_to_pointer(buffer))

        # read actual number of bytes composed by OpenSSL
        signature = buffer.read_string(sig_size)

        # Free the signature created by d2i_ECDSA_SIG above.
        ECDSA_SIG_free(psig)

        signature
      end
    end

    def ecdsa_verify(signature, hash, public_key)
      raise ArgumentError, "Signature is missing" if !signature
      raise ArgumentError, "Hash is missing" if !hash
      raise ArgumentError, "Public key is missing" if !public_key

      autorelease do |pool|
        eckey = pool.new_ec_key

        buf = FFI::MemoryPointer.from_string(public_key)
        eckey = o2i_ECPublicKey(pointer_to_pointer(eckey), pointer_to_pointer(buf), buf.size - 1)
        if eckey.null?
          raise BTCError, "OpenSSL failed to create EC_KEY with public key: #{BTC.to_hex(public_key).inspect}"
        end

        # -1 = error, 0 = bad sig, 1 = good
        hash_buf = FFI::MemoryPointer.from_string(hash)
        sig_buf = FFI::MemoryPointer.from_string(signature)
        result = ECDSA_verify(0, hash_buf, hash_buf.size-1, sig_buf, sig_buf.size-1, eckey)

        if result == 1
          return true
        end

        if result == 0
          Diagnostics.current.add_message("OpenSSL detected invalid ECDSA signature. Signature: #{BTC.to_hex(signature).inspect}; Hash: #{BTC.to_hex(hash).inspect}; Pubkey: #{BTC.to_hex(public_key).inspect}")
        else
          raise BTCError, "OpenSSL failed with error while verifying ECDSA signature. Signature: #{BTC.to_hex(signature).inspect}; Hash: #{BTC.to_hex(hash).inspect}; Pubkey: #{BTC.to_hex(public_key).inspect}"
        end
        return false
      end
      false
    end

    # extract private key from uncompressed DER format
    def private_key_from_der_format(der_key)
      raise ArgumentError, "Missing DER private key" if !der_key

      prepare_if_needed

      buf = FFI::MemoryPointer.from_string(der_key)
      ec_key = d2i_ECPrivateKey(nil, pointer_to_pointer(buf), buf.size-1)
      if ec_key.null?
        raise BTCError, "OpenSSL failed to create EC_KEY with DER private key"
      end
      bn = EC_KEY_get0_private_key(ec_key)
      BN_bn2bin(bn, buf)
      buf.read_string(32)
    end

    # Returns data from bignum
    def data_from_bn(bn, min_length: nil, required_length: nil)
      raise ArgumentError, "Missing big number" if !bn

      length = BN_num_bytes(bn)
      buf = FFI::MemoryPointer.from_string("\x00"*length)
      BN_bn2bin(bn, buf)
      s = buf.read_string(length)
      s = s.rjust(min_length, "\x00") if min_length
      if required_length && s.bytesize != required_length
        raise BTCError, "Non-matching length of the number: #{s.bytesize} bytes vs required #{required_length}"
      end
      s
    end

    protected

    # Returns instance of **SomeType for input of type *SomeType.
    def pointer_to_pointer(pointer)
      FFI::MemoryPointer.new(:pointer).put_pointer(0, pointer)
    end



    # typedef struct ECDSA_SIG_st {
    #   BIGNUM *r;
    #   BIGNUM *s;
    # } ECDSA_SIG;
    class ECDSA_SIG < ::FFI::Struct
      layout :r, :pointer,
             :s, :pointer
    end

    class AutoreleasePool

      LIB = BTC::OpenSSL

      # Returns last created EC_KEY or creates one on the fly.
      attr_reader :ec_key

      # Returns current BN_CTX object or creates one on the fly.
      attr_reader :bn_ctx

      def initialize
        @ec_keys   = []
        @bns       = []
        @ec_points = []
      end

      def ec_key
        @ec_keys.last || new_ec_key
      end

      def bn_ctx
        @bn_ctx ||= LIB.BN_CTX_new()
      end

      def new_ec_key
        eckey = LIB.EC_KEY_new_by_curve_name(NID_secp256k1)
        @ec_keys << eckey
        return eckey
      end

      # Creates new bignum object optionally initialized with binary data (bin2bn)
      def new_bn(data = nil)
        bn = LIB.BN_new()
        if data && data.size > 0
          data_ptr = FFI::MemoryPointer.from_string(data)
          # size-1 to skip \0 terminator
          bn = LIB.BN_bin2bn(data_ptr, data_ptr.size - 1, bn)
        end
        @bns << bn
        return bn
      end

      def new_ec_point
        p = LIB.EC_POINT_new(LIB.group)
        @ec_points << p
        return p
      end

      def drain
        @ec_keys.each   {|eckey| LIB.EC_KEY_free(eckey) }; @ec_keys   = nil
        @bns.each       {|bn|    LIB.BN_free(bn)        }; @bns       = nil
        @ec_points.each {|p|     LIB.EC_POINT_free(p)   }; @ec_points = nil
        if @bn_ctx
          LIB.BN_CTX_free(@bn_ctx)
          @bn_ctx = nil
        end
        return nil
      end

    end

  end
end
