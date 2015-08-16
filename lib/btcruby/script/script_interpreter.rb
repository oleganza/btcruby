if $0 == __FILE__
  require 'btcruby'
  require_relative 'script_flags.rb'
  require_relative 'script_number.rb'
end

module BTC

  MAX_STACK_SIZE = 1000

  # Script is a stack machine (like Forth) that evaluates a predicate
  # returning a bool indicating valid or not.  There are no loops.
  class ScriptInterpreter
    include ScriptFlags

    # Flags specified for this interpreter, not including flags added by plugins.
    attr_accessor :flags
    
    attr_accessor :plugins
    attr_accessor :signature_checker
    attr_accessor :stack
    attr_reader   :altstack
    attr_accessor :error # ScriptError instance

    # Instantiates interpreter with validation flags and an optional checker
    # (required if the scripts use signature-checking opcodes).
    # Checker can be transaction checker or block checker
    def initialize(flags:             SCRIPT_VERIFY_NONE,
                   plugins:           nil,
                   signature_checker: nil,
                   raise_on_failure:  false,
                   max_pushdata_size: MAX_SCRIPT_ELEMENT_SIZE,
                   max_op_count:      MAX_OPS_PER_SCRIPT,
                   max_stack_size:    MAX_STACK_SIZE,
                   integer_max_size:  4,
                   locktime_max_size: 5)
      @flags             = flags
      @plugins           = plugins || []
      @signature_checker = signature_checker
      @raise_on_failure  = raise_on_failure
      @max_pushdata_size = max_pushdata_size
      @max_op_count      = max_op_count
      @max_stack_size    = max_stack_size
      @integer_max_size  = integer_max_size
      @locktime_max_size = locktime_max_size
    end

    # Returns true if succeeded or false in case of failure.
    # If fails, sets the error attribute.
    def verify_script(signature_script: nil, output_script: nil)

      @stack = []
      @altstack = []

      if flag?(SCRIPT_VERIFY_SIGPUSHONLY) && !signature_script.data_only?
        return set_error(SCRIPT_ERR_SIG_PUSHONLY)
      end

      if plugin = plugin_to_handle_scripts(signature_script, output_script)
        return plugin.handle_scripts(
          interpreter: self,
          signature_script: signature_script,
          output_script: output_script
        ) && verify_clean_stack_if_needed
      end

      if !run_script(signature_script)
        # error is set in run_script
        return false
      end

      if !did_execute_signature_script(signature_script)
        # error is set already
        return false
      end

      # FIXME: remove this
      stack_copy = if flag?(SCRIPT_VERIFY_P2SH)
        @stack.dup
      end

      if !run_script(output_script)
        # error is set in run_script
        return false
      end

      if @stack.empty?
        return set_error(SCRIPT_ERR_EVAL_FALSE)
      end

      if cast_to_bool(@stack.last) == false
        return set_error(SCRIPT_ERR_EVAL_FALSE)
      end

      if !did_execute_output_script(output_script)
        # error is set already
        return false
      end

      # Additional validation for pay-to-script-hash (P2SH) transactions:
      if flag?(SCRIPT_VERIFY_P2SH) && output_script.p2sh?

        # scriptSig must be literals-only or validation fails
        if !signature_script.data_only?
          return set_error(SCRIPT_ERR_SIG_PUSHONLY)
        end

        # Restore stack.
        @stack = stack_copy

        # stack cannot be empty here, because if it was the
        # P2SH  HASH <> EQUAL  scriptPubKey would be evaluated with
        # an empty stack and the EvalScript above would return false.
        raise "Stack cannot be empty" if @stack.empty?

        serialized_redeem_script = stack_pop
        begin
          redeem_script = BTC::Script.new(data: serialized_redeem_script)
        rescue => e
          return set_error(SCRIPT_ERR_BAD_OPCODE, "Failed to parse serialized redeem script for P2SH. #{e.message}")
        end

        if !run_script(redeem_script)
          # error is set in run_script
          return false
        end

        if @stack.empty?
          return set_error(SCRIPT_ERR_EVAL_FALSE)
        end

        if cast_to_bool(@stack.last) == false
          return set_error(SCRIPT_ERR_EVAL_FALSE)
        end
      end

      return verify_clean_stack_if_needed
    end









    # Returns true if succeeded or false in case of failure.
    # If fails, sets the error attribute.
    # Used internally in `verify_script` and also in unit tests.
    def run_script(script)

      # Altstack is not shared between individual runs, but we still store it in ivar to make available to the plugins.
      @altstack = []

      number_zero  = ScriptNumber.new(integer: 0)
      number_one   = ScriptNumber.new(integer: 1)
      zero_value = "".b
      false_value = "".b
      true_value = "\x01".b

      opcount = 0
      require_minimal = flag?(SCRIPT_VERIFY_MINIMALDATA)
      condition_flags = []
      index_after_codeseparator = 0
      script.chunks.each_with_index do |chunk, chunk_index|

        opcode = chunk.opcode
        should_execute = !condition_flags.include?(false)

        if chunk.pushdata? && chunk.pushdata.bytesize > @max_pushdata_size
          return set_error(SCRIPT_ERR_PUSH_SIZE)
        end

        # Note how OP_RESERVED does not count towards the opcode limit.
        if opcode > OP_16
          if (opcount += 1) > @max_op_count
            return set_error(SCRIPT_ERR_OP_COUNT)
          end
        end

        if opcode == OP_CAT ||
           opcode == OP_SUBSTR ||
           opcode == OP_LEFT ||
           opcode == OP_RIGHT ||
           opcode == OP_INVERT ||
           opcode == OP_AND ||
           opcode == OP_OR ||
           opcode == OP_XOR ||
           opcode == OP_2MUL ||
           opcode == OP_2DIV ||
           opcode == OP_MUL ||
           opcode == OP_DIV ||
           opcode == OP_MOD ||
           opcode == OP_LSHIFT ||
           opcode == OP_RSHIFT

          return set_error(SCRIPT_ERR_DISABLED_OPCODE)
        end

        if should_execute && 0 <= opcode && opcode <= OP_PUSHDATA4
          # Pushdata (including OP_0).
          if require_minimal && !check_minimal_push(chunk.pushdata, opcode)
            return set_error(SCRIPT_ERR_MINIMALDATA)
          end
          stack_push(chunk.pushdata)
        elsif should_execute || (OP_IF <= opcode && opcode <= OP_ENDIF)

          case opcode
          when OP_1NEGATE, OP_1..OP_16
            # ( -- value)
            num = ScriptNumber.new(integer: opcode - (OP_1 - 1))
            stack_push(num.data)
            # The result of these opcodes should always be the minimal way to push the data
            # they push, so no need for a CheckMinimalPush here.


          # Control Operators
          # -----------------

          when OP_NOP
            # nothing

          when OP_CHECKLOCKTIMEVERIFY
            begin
              if !flag?(SCRIPT_VERIFY_CHECKLOCKTIMEVERIFY)
                # not enabled; treat as a NOP2
                if flag?(SCRIPT_VERIFY_DISCOURAGE_UPGRADABLE_NOPS)
                  return set_error(SCRIPT_ERR_DISCOURAGE_UPGRADABLE_NOPS)
                end
                break # breaks out of begin ... end while false
              end

              if @stack.size < 1
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
              locktime = cast_to_number(@stack.last, max_size: @locktime_max_size)

              # In the rare event that the argument may be < 0 due to
              # some arithmetic being done first, you can always use
              # 0 MAX CHECKLOCKTIMEVERIFY.
              if locktime < 0
                return set_error(SCRIPT_ERR_NEGATIVE_LOCKTIME)
              end

              # Actually compare the specified lock time with the transaction.
              if !signature_checker.check_lock_time(locktime)
                return set_error(SCRIPT_ERR_UNSATISFIED_LOCKTIME)
              end
            end while false

          when OP_NOP1..OP_NOP10
            if flag?(SCRIPT_VERIFY_DISCOURAGE_UPGRADABLE_NOPS)
              return set_error(SCRIPT_ERR_DISCOURAGE_UPGRADABLE_NOPS)
            end

          when OP_IF, OP_NOTIF
            # <expression> if [statements] [else [statements]] endif
            flag = false
            if should_execute
              if @stack.size < 1
                return set_error(SCRIPT_ERR_UNBALANCED_CONDITIONAL)
              end
              flag = cast_to_bool(@stack.last)
              if opcode == OP_NOTIF
                flag = !flag
              end
              stack_pop
            end
            condition_flags.push(flag)

          when OP_ELSE
            if condition_flags.empty?
              return set_error(SCRIPT_ERR_UNBALANCED_CONDITIONAL)
            end
            condition_flags[-1] = !condition_flags.last

          when OP_ENDIF
            if condition_flags.empty?
              return set_error(SCRIPT_ERR_UNBALANCED_CONDITIONAL)
            end
            condition_flags.pop

          when OP_VERIFY
            # (true -- ) or
            # (false -- false) and return
            if @stack.size < 1
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            flag = cast_to_bool(@stack.last)
            if flag
              stack_pop
            else
              return set_error(SCRIPT_ERR_VERIFY)
            end

          when OP_RETURN
            return set_error(SCRIPT_ERR_OP_RETURN)


          # Stack Operations
          # ----------------

          when OP_TOALTSTACK
            if @stack.size < 1
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            @altstack.push(stack_pop)

          when OP_FROMALTSTACK
            if @altstack.size < 1
              return set_error(SCRIPT_ERR_INVALID_ALTSTACK_OPERATION)
            end
            stack_push(@altstack.pop)

          when OP_2DROP
            # (x1 x2 -- )
            if @stack.size < 2
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            stack_pop
            stack_pop

          when OP_2DUP
            # (x1 x2 -- x1 x2 x1 x2)
            if @stack.size < 2
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            a = @stack[-2]
            b = @stack[-1]
            stack_push(a)
            stack_push(b)

          when OP_3DUP
            # (x1 x2 x3 -- x1 x2 x3 x1 x2 x3)
            if @stack.size < 3
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            a = @stack[-3]
            b = @stack[-2]
            c = @stack[-1]
            stack_push(a)
            stack_push(b)
            stack_push(c)

          when OP_2OVER
            # (x1 x2 x3 x4 -- x1 x2 x3 x4 x1 x2)
            if @stack.size < 4
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            a = @stack[-4]
            b = @stack[-3]
            stack_push(a)
            stack_push(b)

          when OP_2ROT
            # (x1 x2 x3 x4 x5 x6 -- x3 x4 x5 x6 x1 x2)
            if @stack.size < 6
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            a = @stack[-6]
            b = @stack[-5]
            @stack[-6...-4] = []
            stack_push(a)
            stack_push(b)

          when OP_2SWAP
            # (x1 x2 x3 x4 -- x3 x4 x1 x2)
            if @stack.size < 4
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            x1x2 = @stack[-4...-2]
            @stack[-4...-2] = []
            @stack += x1x2

          when OP_IFDUP
            # (x - 0 | x x)
            if @stack.size < 1
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            item = @stack.last
            if cast_to_bool(item)
              stack_push(item)
            end

          when OP_DEPTH
            # -- stacksize
            sn = ScriptNumber.new(integer: @stack.size)
            stack_push(sn.data)

          when OP_DROP
            # (x -- )
            if @stack.size < 1
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            stack_pop

          when OP_DUP
            # (x -- x x)
            if @stack.size < 1
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            stack_push(@stack.last)

          when OP_NIP
            # (x1 x2 -- x2)
            if @stack.size < 2
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            @stack.delete_at(-2)

          when OP_OVER
            # (x1 x2 -- x1 x2 x1)
            if @stack.size < 2
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            stack_push(@stack[-2])

          when OP_PICK, OP_ROLL
            # (xn ... x2 x1 x0 n - xn ... x2 x1 x0 xn)
            # (xn ... x2 x1 x0 n - ... x2 x1 x0 xn)
            if @stack.size < 2
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            n = cast_to_number(@stack.last).to_i
            stack_pop
            if n < 0 || n >= @stack.size
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            item = @stack[-n-1]
            if opcode == OP_ROLL
              @stack.delete_at(-n-1)
            end
            stack_push(item)

          when OP_ROT
            # (x1 x2 x3 -- x2 x3 x1)
            #  x2 x1 x3  after first swap
            #  x2 x3 x1  after second swap
            if @stack.size < 3
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            x1 = @stack[-3]
            @stack.delete_at(-3)
            stack_push(x1)

          when OP_SWAP
            # (x1 x2 -- x2 x1)
            if @stack.size < 2
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            x1 = @stack[-2]
            @stack.delete_at(-2)
            stack_push(x1)

          when OP_TUCK
            # (x1 x2 -- x2 x1 x2)
            if @stack.size < 2
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            item = @stack[-1]
            @stack.insert(-3, item) # -1 inserts in the end, -2 before the last item.

          when OP_SIZE
            # (in -- in size)
            if @stack.size < 1
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            sn = ScriptNumber.new(integer: @stack.last.size)
            stack_push(sn.data)


          # Bitwise Logic
          # -------------

          when OP_EQUAL, OP_EQUALVERIFY
          # there is no OP_NOTEQUAL, use OP_NUMNOTEQUAL instead
            # (x1 x2 - bool)
            if @stack.size < 2
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            a = @stack[-2]
            b = @stack[-1]
            equal = (a == b)
            # OP_NOTEQUAL is disabled because it would be too easy to say
            # something like n != 1 and have some wiseguy pass in 1 with extra
            # zero bytes after it (numerically, 0x01 == 0x0001 == 0x000001)
            # if opcode == OP_NOTEQUAL
            #   equal = !equal
            # end
            stack_pop
            stack_pop
            stack_push(equal ? true_value : false_value)
            if opcode == OP_EQUALVERIFY
              if equal
                stack_pop
              else
                return set_error(SCRIPT_ERR_EQUALVERIFY)
              end
            end


          # Numeric
          # -------

          when OP_1ADD,
               OP_1SUB,
               OP_NEGATE,
               OP_ABS,
               OP_NOT,
               OP_0NOTEQUAL
            # (in -- out)
            if @stack.size < 1
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end

            bn = cast_to_number(@stack.last)
            case opcode
            when OP_1ADD
              bn += 1
            when OP_1SUB
              bn -= 1
            when OP_NEGATE
              bn = -bn
            when OP_ABS
              bn = -bn if bn < 0
            when OP_NOT
              bn = ScriptNumber.new(boolean: (bn == 0))
            when OP_0NOTEQUAL
              bn = ScriptNumber.new(boolean: (bn != 0))
            else
              raise "invalid opcode"
            end
            stack_pop
            stack_push(bn.data);


          when OP_ADD, OP_SUB, OP_BOOLAND..OP_MAX
            # (x1 x2 -- out)
            if @stack.size < 2
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end

            bn1 = cast_to_number(@stack[-2])
            bn2 = cast_to_number(@stack[-1])
            bn = ScriptNumber.new(integer: 0)

            case opcode
            when OP_ADD
              bn = bn1 + bn2
            when OP_SUB
              bn = bn1 - bn2
            when OP_BOOLAND
              bn = ScriptNumber.new(boolean: ((bn1 != 0) && (bn2 != 0)))
            when OP_BOOLOR
              bn = ScriptNumber.new(boolean: ((bn1 != 0) || (bn2 != 0)))
            when OP_NUMEQUAL, OP_NUMEQUALVERIFY
              bn = ScriptNumber.new(boolean: (bn1 == bn2))
            when OP_NUMNOTEQUAL
              bn = ScriptNumber.new(boolean: (bn1 != bn2))
            when OP_LESSTHAN
              bn = ScriptNumber.new(boolean: (bn1 < bn2))
            when OP_GREATERTHAN
              bn = ScriptNumber.new(boolean: (bn1 > bn2))
            when OP_LESSTHANOREQUAL
              bn = ScriptNumber.new(boolean: (bn1 <= bn2))
            when OP_GREATERTHANOREQUAL
              bn = ScriptNumber.new(boolean: (bn1 >= bn2))
            when OP_MIN
              bn = (bn1 < bn2 ? bn1 : bn2)
            when OP_MAX
              bn = (bn1 > bn2 ? bn1 : bn2)
            else
              raise "Invalid opcode"
            end
            stack_pop
            stack_pop
            stack_push(bn.data)

            if opcode == OP_NUMEQUALVERIFY
              if cast_to_bool(@stack[-1])
                stack_pop
              else
                return set_error(SCRIPT_ERR_NUMEQUALVERIFY)
              end
            end

          when OP_WITHIN
            # (x min max -- out)
            if @stack.size < 3
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            bn1 = cast_to_number(@stack[-3])
            bn2 = cast_to_number(@stack[-2])
            bn3 = cast_to_number(@stack[-1])
            flag = ((bn2 <= bn1) && (bn1 < bn3))
            stack_pop
            stack_pop
            stack_pop
            stack_push(flag ? true_value : false_value)

          # Crypto
          # ------

          when OP_RIPEMD160..OP_HASH256
            # (in -- hash)
            if @stack.size < 1
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end
            item = @stack[-1]
            hash = case opcode
            when OP_RIPEMD160
              BTC.ripemd160(item)
            when OP_SHA1
              BTC.sha1(item)
            when OP_SHA256
              BTC.sha256(item)
            when OP_HASH160
              BTC.hash160(item)
            when OP_HASH256
              BTC.hash256(item)
            end
            stack_pop
            stack_push(hash)

          when OP_CODESEPARATOR
            # Hash starts after the code separator
            index_after_codeseparator = chunk_index + 1

          when OP_CHECKSIG, OP_CHECKSIGVERIFY
            # (sig pubkey -- bool)
            if @stack.size < 2
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end

            sig = @stack[-2]
            pubkey    = @stack[-1]

            # Subset of script starting at the most recent codeseparator
            subscript = script.subscript(index_after_codeseparator..-1)

            # Drop the signature, since there's no way for a signature to sign itself
            # Consensus-critical code: must replace sig with minimal encoding.
            subscript = subscript.find_and_delete(BTC::Script.new << sig)

            if !check_signature_encoding(sig) || !check_pubkey_encoding(pubkey)
              # error is set already
              return false
            end

            success = signature_checker.check_signature(
              script_signature: sig,
              public_key:       pubkey,
              script:           subscript
            )

            stack_pop
            stack_pop
            stack_push(success ? true_value : false_value)

            if opcode == OP_CHECKSIGVERIFY
              if success
                stack_pop
              else
                return set_error(SCRIPT_ERR_CHECKSIGVERIFY)
              end
            end


          when OP_CHECKMULTISIG, OP_CHECKMULTISIGVERIFY
            # ([sig ...] num_of_signatures [pubkey ...] num_of_pubkeys -- bool)

            i = 1
            if @stack.size < i
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end

            keys_count = cast_to_number(@stack[-i]).to_i
            if keys_count < 0 || keys_count > 20
              return set_error(SCRIPT_ERR_PUBKEY_COUNT)
            end
            opcount += keys_count
            if opcount > @max_op_count
              return set_error(SCRIPT_ERR_OP_COUNT)
            end
            ikey = (i+=1)
            i += keys_count
            if @stack.size < i
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end

            sigs_count = cast_to_number(@stack[-i]).to_i
            if sigs_count < 0 || sigs_count > keys_count
              return set_error(SCRIPT_ERR_SIG_COUNT)
            end

            isig = (i+=1)
            i += sigs_count

            if @stack.size < i
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end

            # Subset of script starting at the most recent codeseparator

            # Subset of script starting at the most recent codeseparator
            subscript = script.subscript(index_after_codeseparator..-1)

            # Drop the signatures, since there's no way for a signature to sign itself
            # Consensus-critical code: must replace sig with minimal encoding.
            sigs_count.times do |k|
              sig = @stack[-isig-k]
              subscript = subscript.find_and_delete(BTC::Script.new << sig)
            end

            success = true
            while success && sigs_count > 0
              sig = @stack[-isig]
              pubkey = @stack[-ikey]
              # Note how this makes the exact order of pubkey/signature evaluation
              # distinguishable by CHECKMULTISIG NOT if the STRICTENC flag is set.
              # See the script_(in)valid tests for details.
              if !check_signature_encoding(sig) || !check_pubkey_encoding(pubkey)
                # error is set already
                return false
              end

              # Check signature
              ok = signature_checker.check_signature(
                script_signature: sig,
                public_key:       pubkey,
                script:           subscript
              )
              if ok
                isig += 1
                sigs_count -= 1
              end
              ikey += 1
              keys_count -= 1

              # If there are more signatures left than keys left,
              # then too many signatures have failed. Exit early,
              # without checking any further signatures.
              if sigs_count > keys_count
                success = false
              end
            end

            # Clean up stack of actual arguments
            while (i-=1) > 0  # Bitcoin Core: while (i-- > 1)
              stack_pop
            end

            # A bug causes CHECKMULTISIG to consume one extra argument
            # whose contents were not checked in any way.
            #
            # Unfortunately this is a potential source of mutability,
            # so optionally verify it is exactly equal to zero prior
            # to removing it from the stack.
            if @stack.size < 1
              return set_error(SCRIPT_ERR_INVALID_STACK_OPERATION)
            end

            if flag?(SCRIPT_VERIFY_NULLDUMMY) && @stack[-1].size > 0
              return set_error(SCRIPT_ERR_SIG_NULLDUMMY)
            end
            stack_pop
            stack_push(success ? true_value : false_value)
            if opcode == OP_CHECKMULTISIGVERIFY
              if success
                stack_pop
              else
                return set_error(SCRIPT_ERR_CHECKMULTISIGVERIFY)
              end
            end

          else # unknown opcode
            return set_error(SCRIPT_ERR_BAD_OPCODE)

          end # case opcode
        end # within IF scope

        # Size limits
        if @stack.size + @altstack.size > @max_stack_size
          return set_error(SCRIPT_ERR_STACK_SIZE)
        end

      end # each chunk

      if !condition_flags.empty?
        return set_error(SCRIPT_ERR_UNBALANCED_CONDITIONAL)
      end

      return true
    rescue ScriptNumberError => e
      return set_error(SCRIPT_ERR_UNKNOWN_ERROR, e.message)
    end # run_script


    def stack_pop
      r = @stack.pop
      #puts "POPPED FROM STACK: #{@stack.map{|s|s.to_hex}.join(' ')}"
      r
    end

    def stack_push(x)
      @stack.push(x)
      #puts "PUSHED TO STACK:   #{@stack.map{|s|s.to_hex}.join(' ')}"
    end

    # aka CheckMinimalPush(const valtype& data, opcodetype opcode)
    def check_minimal_push(data, opcode)
      if data.bytesize == 0
        # Could have used OP_0.
        return opcode == OP_0
      elsif data.bytesize == 1 && data.bytes[0] >= 1 && data.bytes[0] <= 16
        # Could have used OP_1 .. OP_16.
        return opcode == OP_1 + (data.bytes[0] - 1)
      elsif data.bytesize == 1 && data.bytes[0] == 0x81
        # Could have used OP_1NEGATE.
        return opcode == OP_1NEGATE
      elsif data.bytesize <= 75
        # Could have used a direct push (opcode indicating number of bytes pushed + those bytes).
        return opcode == data.bytesize
      elsif data.bytesize <= 255
        # Could have used OP_PUSHDATA.
        return opcode == OP_PUSHDATA1
      elsif (data.bytesize <= 65535)
        # Could have used OP_PUSHDATA2.
        return opcode == OP_PUSHDATA2
      end
      return true
    end

    def check_signature_encoding(sig)
      # Empty signature. Not strictly DER encoded, but allowed to provide a
      # compact way to provide an invalid signature for use with CHECK(MULTI)SIG
      if sig.size == 0
        return true
      end
      if flag?(SCRIPT_VERIFY_DERSIG | SCRIPT_VERIFY_LOW_S | SCRIPT_VERIFY_STRICTENC) && !valid_signature_encoding(sig)
        return set_error(SCRIPT_ERR_SIG_DER)
      elsif flag?(SCRIPT_VERIFY_LOW_S) && !low_der_signature(sig)
        return set_error(SCRIPT_ERR_SIG_HIGH_S)
      elsif flag?(SCRIPT_VERIFY_STRICTENC) && !defined_hashtype_signature(sig)
        return set_error(SCRIPT_ERR_SIG_HASHTYPE)
      end
      return true
    end

    def check_pubkey_encoding(pubkey)
      if flag?(SCRIPT_VERIFY_STRICTENC) && !compressed_or_uncompressed_pubkey(pubkey)
        return set_error(SCRIPT_ERR_PUBKEYTYPE)
      end
      return true
    end

    def valid_signature_encoding(sig)
      BTC::Key.validate_script_signature(sig, verify_lower_s: false, verify_hashtype: false)
    end

    def low_der_signature(sig)
      BTC::Key.validate_script_signature(sig, verify_lower_s: true, verify_hashtype: false)
    end

    def defined_hashtype_signature(sig)
      BTC::Key.validate_script_signature(sig, verify_lower_s: false, verify_hashtype: true)
    end

    def compressed_or_uncompressed_pubkey(pubkey)
      BTC::Key.validate_public_key(pubkey)
    end

    # If multiple flags are provided, returns true if any of them are present
    def flag?(flags)
      (all_flags & flags) != 0
    end

    def all_flags
      @plugins.inject(@flags) do |f, p|
        f | p.extra_flags
      end
    end

    def cast_to_number(data,
                       require_minimal: flag?(SCRIPT_VERIFY_MINIMALDATA),
                       max_size: @integer_max_size)
      ScriptNumber.new(data: data, require_minimal: require_minimal, max_size: max_size)
    end

    def cast_to_bool(data)
      data.bytes.each_with_index do |byte, i|
        if byte != 0
          # Can be negative zero
          if byte == 0x80 && i == (data.bytesize - 1)
            return false
          end
          return true
        end
      end
      return false
    end

    def set_error(code, message = nil)
      error = ScriptError.new(code, message)
      raise "#{error.description} (#{code.inspect})" if @raise_on_failure
      @error = error
      false
    end

    private

    def plugin_to_handle_scripts(signature_script, output_script)
      @plugins.each do |plugin|
        if plugin.should_handle_scripts(interpreter: self, signature_script: signature_script, output_script: output_script)
          return plugin
        end
      end
      nil
    end

    def plugin_to_handle_output_script(output_script)
      @plugins.each do |plugin|
        if plugin.should_handle_output_script(interpreter: self, signature_script: signature_script, output_script: output_script)
          return plugin
        end
      end
      nil
    end

    def did_execute_signature_script(signature_script)
      @plugins.each do |plugin|
        if !plugin.did_execute_signature_script(interpreter: self, signature_script: signature_script)
          return false
        end
      end
    end

    def did_execute_output_script(output_script)
      @plugins.each do |plugin|
        if !plugin.did_execute_output_script(interpreter: self, output_script: output_script)
          return false
        end
      end
    end

    def verify_clean_stack_if_needed
      # The CLEANSTACK check is only performed after potential P2SH evaluation,
      # as the non-P2SH evaluation of a P2SH script will obviously not result in
      # a clean stack (the P2SH inputs remain).
      if flag?(SCRIPT_VERIFY_CLEANSTACK)
        # Disallow CLEANSTACK without P2SH, as otherwise a switch CLEANSTACK->P2SH+CLEANSTACK
        # would be possible, which is not a softfork (and P2SH should be one).
        if !flag?(SCRIPT_VERIFY_P2SH)
          raise ArgumentError, "CLEANSTACK without P2SH is disallowed"
        end
        if @stack.size != 1
          return set_error(SCRIPT_ERR_CLEANSTACK, "Stack must be clean (should contain one item 'true')")
        end
      end
      return true
    end

  end
end

if $0 == __FILE__
  require 'btcruby'

end