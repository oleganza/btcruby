module BTC
  class TransactionSignatureChecker
    include SignatureChecker
    
    attr_accessor :transaction
    attr_accessor :input_index
    def initialize(transaction: nil, input_index: nil)
      @transaction = transaction
      @input_index = input_index
    end
    
    def check_signature(script_signature:nil, public_key:nil, script:nil)
      # Signature must be long enough to contain a sighash byte.
      return false if script_signature.size < 1
      
      hashtype = script_signature[-1].bytes.first

      # Extract raw ECDSA signature by stripping off the last hashtype byte
      ecdsa_sig = script_signature[0..-2]
      
      key = BTC::Key.new(public_key: public_key)
      hash = @transaction.signature_hash(input_index: @input_index, output_script: script, hash_type: hashtype)
      result = key.verify_ecdsa_signature(ecdsa_sig, hash)
      return result
    rescue BTC::FormatError => e # public key is invalid
      return false
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
           (@transaction.lock_time <  LOCKTIME_THRESHOLD && lock_time <  LOCKTIME_THRESHOLD) ||
           (@transaction.lock_time >= LOCKTIME_THRESHOLD && lock_time >= LOCKTIME_THRESHOLD)
       )
        return false
      end

      # Now that we know we're comparing apples-to-apples, the
      # comparison is a simple numeric one.
      if lock_time > @transaction.lock_time
        return false
      end

      # Finally the nLockTime feature can be disabled and thus
      # CHECKLOCKTIMEVERIFY bypassed if every txin has been
      # finalized by setting nSequence to maxint. The
      # transaction would be allowed into the blockchain, making
      # the opcode ineffective.
      #
      # Testing if this vin is not final is sufficient to
      # prevent this condition. Alternatively we could test all
      # inputs, but testing just this input minimizes the data
      # required to prove correct CHECKLOCKTIMEVERIFY execution.
      if @transaction.inputs[@input_index].final?
        return false
      end

      return true
    end
    
  end
end