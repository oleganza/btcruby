module BTC
  # Proof of work is specified using several terms.
  # 1. `target` is big unsigned integer derived from 256-bit hash (interpreted as little-endian integer).
  #     Hash of a valid block should be below target.
  # 2. `bits` is a 'satoshi compact' representation of a target as uint32.
  # 3. `difficulty` is a floating point multiple of the minimum difficulty.
  #     Difficulty = 2 means the block is 2x more difficult than the minimal difficulty.
  module ProofOfWork
    extend self

    MAX_TARGET_MAINNET = 0x00000000ffff0000000000000000000000000000000000000000000000000000
    MAX_TARGET_TESTNET = 0x00000007fff80000000000000000000000000000000000000000000000000000

    # Note on Satoshi Compact format (used for 'bits' value).
    #
    # The "compact" format is a representation of a whole
    # number N using an unsigned 32bit number similar to a
    # floating point format.
    # The most significant 8 bits are the unsigned exponent of base 256.
    # This exponent can be thought of as "number of bytes of N".
    # The lower 23 bits are the mantissa.
    # Bit number 24 (0x800000) represents the sign of N.
    # N = (-1^sign) * mantissa * 256^(exponent-3)
    #
    # Satoshi's original implementation used BN_bn2mpi() and BN_mpi2bn().
    # MPI uses the most significant bit of the first byte as sign.
    # Thus 0x1234560000 is compact (0x05123456)
    # and  0xc0de000000 is compact (0x0600c0de)
    # (0x05c0de00) would be -0x40de000000

    # Converts 256-bit integer to 32-bit compact representation.
    def bits_from_target(target)
      exponent = 3
      signed = (target < 0)
      target = -target if signed
      while target > 0x7fffff
        target >>= 8
        exponent += 1
      end
      # The 0x00800000 bit denotes the sign.
      # Thus, if it is already set, divide the mantissa by 256 and increase the exponent.
      if (target & 0x00800000) > 0
        target >>= 8
        exponent += 1
      end
      result = (exponent << 24) + target
      result = result | 0x00800000 if signed
      result
    end

    # Converts 32-bit compact representation to a 256-bit integer.
    def target_from_bits(bits)
      exponent = ((bits >> 24) & 0xff)
      mantissa = bits & 0x7fffff
      mantissa *= -1 if (bits & 0x800000) > 0
      (mantissa * (256**(exponent-3))).to_i
    end

    # Computes bits from difficulty.
    # Could be inaccurate since difficulty is a limited-precision floating-point number.
    # Default max_target is for Bitcoin mainnet.
    def bits_from_difficulty(difficulty, max_target: MAX_TARGET_MAINNET)
      bits_from_target(target_from_difficulty(difficulty, max_target: max_target))
    end

    # Computes difficulty from bits. 
    # Default max_target is for Bitcoin mainnet.
    def difficulty_from_bits(bits, max_target: MAX_TARGET_MAINNET)
      difficulty_from_target(target_from_bits(bits), max_target: max_target)
    end

    # Computes target from difficulty. 
    # Could be inaccurate since difficulty is a limited-precision floating-point number.
    # Default max_target is for Bitcoin mainnet.
    def target_from_difficulty(difficulty, max_target: MAX_TARGET_MAINNET)
      (max_target / difficulty).round.to_i
    end
    
    # Compute relative difficulty from a given target. 
    # E.g. returns 2.5 if target is 2.5 times harder to reach than the max_target.
    # Default max_target is for Bitcoin mainnet.
    def difficulty_from_target(target, max_target: MAX_TARGET_MAINNET)
      (max_target / target.to_f)
    end

    # Converts target integer to a binary 32-byte hash.
    def hash_from_target(target)
      bytes = []
      while target > 0
        bytes << (target % 256)
        target /= 256
      end
      BTC::Data.data_from_bytes(bytes).ljust(32, "\x00".b)
    end

    # Converts 32-byte hash to target integer (hash is treated as little-endian integer)
    def target_from_hash(hash)
      target = 0
      i = 0
      hash.each_byte do |byte|
        target += byte * (256**i)
        i += 1
      end
      target
    end

    # TODO: add retargeting calculation routines

  end # ProofOfWork
end # BTC
