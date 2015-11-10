module BTC
  # Performs Pay-to-Script-Hash (BIP16) evaluation
  class P2SHExtension
    include ScriptInterpreterExtension

    # Returns additional flags to be available to #flag? checks during script execution.
    # This way one extension can affect evaluation of another.
    def extra_flags
      SCRIPT_VERIFY_P2SH
    end

    # Every extension gets this callback. If extension return `false`, execution is stopped and interpreter returns `false`.
    # Default value is `true`.
    def did_execute_signature_script(interpreter: nil, signature_script: nil)
      @signature_script = signature_script
      @stack_copy = interpreter.stack.dup
      true
    end

    def did_execute_output_script(interpreter: nil, output_script: nil)
      # Cleanup ivars
      stack_copy = @stack_copy
      @stack_copy = nil

      signature_script = @signature_script
      @signature_script = nil

      # NOTE: check for empty stack or "false" item happens
      # in ScriptInterpreter before this callback is invoked.

      # If output script is not P2SH, do nothing.
      return true if !output_script.p2sh?

      # Additional validation for pay-to-script-hash (P2SH) transactions:

      # scriptSig must be literals-only or validation fails
      if !signature_script.data_only?
        return interpreter.set_error(SCRIPT_ERR_SIG_PUSHONLY)
      end

      # Restore stack.
      interpreter.stack = stack_copy

      # stack cannot be empty here, because if it was the
      # P2SH  HASH <> EQUAL  scriptPubKey would be evaluated with
      # an empty stack and the EvalScript above would return false.
      raise "Stack cannot be empty" if stack_copy.empty?

      serialized_redeem_script = interpreter.stack.pop
      begin
        redeem_script = BTC::Script.new(data: serialized_redeem_script)
      rescue => e
        return interpreter.set_error(SCRIPT_ERR_BAD_OPCODE, "Failed to parse serialized redeem script for P2SH. #{e.message}")
      end

      # Actually execute the script.
      if !interpreter.run_script(redeem_script)
        # error is set in run_script
        return false
      end

      if interpreter.stack.empty?
        return interpreter.set_error(SCRIPT_ERR_EVAL_FALSE)
      end

      if interpreter.cast_to_bool(interpreter.stack.last) == false
        return interpreter.set_error(SCRIPT_ERR_EVAL_FALSE)
      end

      return true
    end

  end
end