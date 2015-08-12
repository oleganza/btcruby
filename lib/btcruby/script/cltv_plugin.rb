module BTC
  # Performs CHECKLOCKTIMEVERIFY evaluation
  class CLTVPlugin
    include ScriptInterpreterPlugin

    # Default `locktime_max_size` is 5.
    # Default `lock_time_checker` equals current interpreter's signature checker.
    def initialize(locktime_max_size: nil, lock_time_checker: nil)
      @locktime_max_size = locktime_max_size || 5
      @lock_time_checker = lock_time_checker
    end

    def extra_flags
      BTC::ScriptFlags::SCRIPT_VERIFY_CHECKLOCKTIMEVERIFY
    end

    def should_handle_opcode(interpreter: nil, opcode: nil)
      opcode == OP_CHECKLOCKTIMEVERIFY
    end

    # Returns `false` if failed to execute the opcode.
    def handle_opcode(interpreter: nil, opcode: nil)
      # We are not supposed to handle any other opcodes here.
      return false if opcode != OP_CHECKLOCKTIMEVERIFY

      if interpreter.stack.size < 1
        return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
      end

      # Note that elsewhere numeric opcodes are limited to
      # operands in the range -2**31+1 to 2**31-1, however it is
      # legal for opcodes to produce results exceeding that
      # range. This limitation is implemented by CScriptNum's
      # default 4-byte limit.
      #
      # If we kept to that limit we'd have a year 2038 problem,
      # even though the nLockTime field in transactions
      # themselves is uint32 which only becomes meaningless
      # after the year 2106.
      #
      # Thus as a special case we tell CScriptNum to accept up
      # to 5-byte bignums, which are good until 2**39-1, well
      # beyond the 2**32-1 limit of the nLockTime field itself.
      locktime = interpreter.cast_to_number(interpreter.stack.last, max_size: @locktime_max_size)

      # In the rare event that the argument may be < 0 due to
      # some arithmetic being done first, you can always use
      # 0 MAX CHECKLOCKTIMEVERIFY.
      if locktime < 0
        return interpreter.set_error(SCRIPT_ERR_NEGATIVE_LOCKTIME)
      end

      # Actually compare the specified lock time with the transaction.
      checker = @lock_time_checker || interpreter.signature_checker
      if !checker.check_lock_time(locktime)
        return set_error(SCRIPT_ERR_UNSATISFIED_LOCKTIME)
      end

      return true
    end

  end
end
