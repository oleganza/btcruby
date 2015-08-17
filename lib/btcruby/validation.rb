module BTC
  # "reject" message codes
  REJECT_MALFORMED       = 0x01
  REJECT_INVALID         = 0x10
  REJECT_OBSOLETE        = 0x11
  REJECT_DUPLICATE       = 0x12
  REJECT_NONSTANDARD     = 0x40
  REJECT_DUST            = 0x41
  REJECT_INSUFFICIENTFEE = 0x42
  REJECT_CHECKPOINT      = 0x43

  class Validation
    
    def initialize(
        max_block_size: MAX_BLOCK_SIZE,
        min_coinbase_size: 2,
        max_coinbase_size: 100,
        max_money: MAX_MONEY
      )
      @max_block_size = max_block_size
      @min_coinbase_size = min_coinbase_size
      @max_coinbase_size = max_coinbase_size
      @max_money = max_money
    end
    
    def check_transaction(tx, state)
      # Basic checks that don't depend on any context
      if tx.inputs.empty?
        return state.DoS(10, false, REJECT_INVALID, "bad-txns-vin-empty")
      end
      if tx.outputs.empty?
        return state.DoS(10, false, REJECT_INVALID, "bad-txns-vout-empty")
      end

      # Size limits
      if tx.data.bytesize > @max_block_size
        return state.DoS(100, false, REJECT_INVALID, "bad-txns-oversize")
      end

      # Check for negative or overflow output values
      tx.outputs.inject(0) do |total, txout|
        if txout.value < 0
          return state.DoS(100, false, REJECT_INVALID, "bad-txns-vout-negative")
        end
        if txout.value > @max_money
          return state.DoS(100, false, REJECT_INVALID, "bad-txns-vout-toolarge")
        end
        total += txout.value
        if !check_money_range(total)
          return state.DoS(100, false, REJECT_INVALID, "bad-txns-txouttotal-toolarge")
        end
        total
      end

      # Check for duplicate inputs
      used_outpoints = {} # outpoint => true
      tx.inputs.each do |txin|
        if used_outpoints[txin.outpoint]
          return state.DoS(100, false, REJECT_INVALID, "bad-txns-inputs-duplicate")
        end
        used_outpoints[txin.outpoint] = true
      end

      if tx.coinbase?
        cb_size = tx.inputs[0].coinbase_data.bytesize
        if cb_size < @min_coinbase_size || cb_size > @max_coinbase_size
          return state.DoS(100, false, REJECT_INVALID, "bad-cb-length")
        end
      else
        tx.inputs.each do |txin|
          if txin.outpoint.null?
            return state.DoS(10, false, REJECT_INVALID, "bad-txns-prevout-null")
          end
        end
      end
      return true
    end
    
    def check_money_range(value)
      value >= 0 && value <= @max_money
    end
  end
  
  class ValidationState
    def DoS(level, return_value = false, reject_code = 0, reject_reason = "", corruption = false, debug_message = "")
      # TODO: set the state
      return_value
    end
  end
end
