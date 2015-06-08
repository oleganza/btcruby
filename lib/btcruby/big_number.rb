# OpenSSL-compatible BigNumber API.
module BTC
  class BigNumber

    # Ruby Integer representation (Fixnum or Bignum)
    attr_reader :integer

    # Raw little-endian signed integer data
    attr_reader :signed_little_endian

    # OpenSSL-compatible big-endian signed integer data
    attr_reader :unsigned_big_endian

    # Initializes with one of the formats:
    # 1) Raw little-endian data extracted from MPI,
    # 2) Native OpenSSL BIGNUM big-endian unsigned big integer,
    # 3) Ruby Integer (Fixnum or Bignum)
    def initialize(signed_little_endian: nil, unsigned_big_endian: nil, integer: nil)
      if signed_little_endian

        raise "Not Implemented"

      elsif unsigned_big_endian

        raise "Not Implemented"

      elsif integer
        @integer = integer
      else
        raise ArgumentError, "One of the arguments must not be nil"
      end
    end

    def integer
      @integer
    end

    def signed_little_endian
      raise "Not Implemented" # reversed mpi with stripped 4-byte length prefix
    end

    def unsigned_big_endian
      raise "Not Implemented" # bin2bn
    end

  end # BigNumber
end # BTC
