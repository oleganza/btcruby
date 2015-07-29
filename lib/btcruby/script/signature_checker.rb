module BTC
  # Protocol for signature checkers
  module SignatureChecker
    # Returns a boolean indicating if signature is valid for the given public key
    def check_signature(script_signature: nil, public_key:nil, script:nil)
      false
    end
    # Returns a boolean indicating if lock time is valid.
    # lock_time is ScriptNumber instance.
    def check_lock_time(lock_time)
      false
    end
  end
end
