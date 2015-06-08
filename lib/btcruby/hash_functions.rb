require 'digest/sha1'
require 'digest/sha2'
require 'digest/rmd160'
require 'digest/hmac'

module BTC
  
  # This allows doing `BTC.sha256(...)`
  module HashFunctions; end
  include HashFunctions
  extend self

  module HashFunctions

    def sha1(data)
      raise ArgumentError, "Data is missing" if !data
      Digest::SHA1.digest(data)
    end

    def sha256(data)
      raise ArgumentError, "Data is missing" if !data
      Digest::SHA256.digest(data)
    end

    def sha512(data)
      raise ArgumentError, "Data is missing" if !data
      Digest::SHA512.digest(data)
    end

    def ripemd160(data)
      raise ArgumentError, "Data is missing" if !data
      Digest::RMD160.digest(data)
    end

    def hash256(data)
      sha256(sha256(data))
    end

    def hash160(data)
      ripemd160(sha256(data))
    end

    def hmac_sha256(data: nil, key: nil)
      raise ArgumentError, "Data is missing" if !data || !key
      Digest::HMAC.digest(data, key, Digest::SHA256)
    end

    def hmac_sha512(data: nil, key: nil)
      raise ArgumentError, "Data is missing" if !data || !key
      Digest::HMAC.digest(data, key, Digest::SHA512)
    end

  end
end
