require 'ffi'

module BTC
  # Bindings to Pieter Wuille's libsecp256k1.
  # This is not included by default, to enable use:
  # require 'btcruby/secp256k1'
  module Secp256k1
    include ::FFI::Library
    extend self

    ffi_lib 'secp256k1'

    SECP256K1_FLAGS_TYPE_CONTEXT = (1 << 0)
    SECP256K1_FLAGS_BIT_CONTEXT_VERIFY = (1 << 8)
    SECP256K1_FLAGS_BIT_CONTEXT_SIGN   = (1 << 9)
    SECP256K1_CONTEXT_SIGN   = (SECP256K1_FLAGS_TYPE_CONTEXT | SECP256K1_FLAGS_BIT_CONTEXT_SIGN)

    # Note: this struct is opaque, but public. Its size will eventually be guaranteed.
    # See https://github.com/bitcoin/secp256k1/issues/288
    # typedef struct {
    #   unsigned char data[65];
    # } secp256k1_ecdsa_signature_t;
    class Signature < ::FFI::Struct
      layout :data, [:uint8, 65]
    end

    attach_function :secp256k1_context_create,                [:int],                                                       :pointer
    attach_function :secp256k1_context_destroy,               [:pointer],                                                   :void
    attach_function :secp256k1_ecdsa_sign,                    [:pointer, :pointer, :pointer, :pointer, :pointer, :pointer], :int
    attach_function :secp256k1_ecdsa_verify,                  [:pointer, :pointer, :pointer, :pointer],                     :int
    attach_function :secp256k1_ecdsa_signature_serialize_der, [:pointer, :pointer, :pointer, :pointer],                     :int
    attach_function :secp256k1_ecdsa_signature_parse_der,     [:pointer, :pointer, :pointer, :int],                         :int

    def ecdsa_signature(hash, privkey)
      raise ArgumentError, "Hash is missing" if !hash
      raise ArgumentError, "Private key is missing" if !privkey
      
      with_context(SECP256K1_CONTEXT_SIGN) do |ctx|
        hash_buf = FFI::MemoryPointer.new(:uchar, hash.bytesize)
        hash_buf.put_bytes(0, hash)

        sig = Signature.new

        privkey_buf = FFI::MemoryPointer.new(:uchar, privkey.bytesize)
        privkey_buf.put_bytes(0, privkey)
        
        if secp256k1_ecdsa_sign(ctx, sig.pointer, hash_buf, privkey_buf, nil, nil) == 1
          # Serialize an ECDSA signature in DER format.
          bufsize = 72
          output_pointer = FFI::MemoryPointer.new(:uint8, bufsize)
          outputlen_pointer = FFI::MemoryPointer.new(:uint).put_uint(0, bufsize)
          if secp256k1_ecdsa_signature_serialize_der(ctx, output_pointer, outputlen_pointer, sig.pointer) == 1
            actual_length = outputlen_pointer.read_uint
            return output_pointer.read_string(actual_length)
          end
        end
        return nil
      end
    end

    def ecdsa_verify(signature, hash, public_key)
      raise ArgumentError, "Signature is missing" if !signature
      raise ArgumentError, "Hash is missing" if !hash
      raise ArgumentError, "Public key is missing" if !public_key
      
      # TODO:...
    end

    def with_context(options = 0)
      begin
        ctx = secp256k1_context_create(options)
        yield(ctx)
      ensure
        secp256k1_context_destroy(ctx)
      end
    end

  end
end
