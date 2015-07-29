module BTC
  class TestSignatureChecker
    include SignatureChecker
    
    def initialize(signature_hash: nil, timestamp: nil)
      @signature_hash = signature_hash
      @timestamp = timestamp
    end
    
    # for testing check_signature
    def signature_hash
      @signature_hash
    end
    
    # for testing check_lock_time
    def timestamp
      @timestamp
    end
    
    def check_signature(script_signature:nil, public_key:nil, script:nil)
      # Signature must be long enough to contain a sighash byte.
      return false if script_signature.size < 1
      
      # Extract raw ECDSA signature by stripping off the last hashtype byte
      ecdsa_sig = script_signature[0..-2]

      key = BTC::Key.new(public_key: public_key)
      result = key.verify_ecdsa_signature(ecdsa_sig, hash)
      return result
    end

    def check_lock_time(lock_time)
      # There are two times of nLockTime: lock-by-blockheight
      # and lock-by-blocktime, distinguished by whether
      # nLockTime < LOCKTIME_THRESHOLD.
      #
      # We want to compare apples to apples, so fail the script
      # if the type of nLockTime being tested is not the same as
      # the nLockTime in the transaction.
      if !(
           (timestamp <  LOCKTIME_THRESHOLD && lock_time <  LOCKTIME_THRESHOLD) ||
           (timestamp >= LOCKTIME_THRESHOLD && lock_time >= LOCKTIME_THRESHOLD)
       )
        return false
      end

      # Now that we know we're comparing apples-to-apples, the
      # comparison is a simple numeric one.
      return timestamp >= lock_time
    end
    
  end
end