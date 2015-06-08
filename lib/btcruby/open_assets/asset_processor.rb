# Implementation of OpenAssets protocol.
# https://github.com/OpenAssets/open-assets-protocol/blob/master/specification.mediawiki
require_relative 'asset_transaction.rb'
module BTC
  # AssetProcessor implements verification and discovery of assets.
  # This assumes that underlying Bitcoin transactions are valid and not double-spent.
  # Only OpenAssets validation is applied to determine which outputs are holding which assets and how much.
  class AssetProcessor

    # AssetProcessorSource instance that provides transactions.
    attr_accessor :source

    # Network to use for encoding AssetIDs. Default is `Network.default`.
    attr_accessor :network

    def initialize(source: nil, network: nil)
      raise ArgumentError, "Source is missing." if !source
      @source = source
      @network = network || Network.default
    end

    # Scans backwards and validates every AssetTransaction on the way.
    # Does not verify Bitcoin transactions (assumes amounts and scripts are already validated).
    # Updates verified flags on the asset transaction.
    # Returns `true` if asset transaction is verified succesfully.
    # Returns `false` otherwise.
    def verify_asset_transaction(asset_transaction)
      raise ArgumentError, "Asset Transaction is missing" if !asset_transaction

      # Perform a depth-first scanning.
      # When completed, we'll only have transactions that have all previous txs fully verified.
      atx_stack = [ asset_transaction ]
      i = 0
      max_size = atx_stack.size
      while i < atx_stack.size # note: array dynamically changes as we scan it
        atx = atx_stack[i]
        BTC::Invariant(atx.is_a?(AssetTransaction), "Must be AssetTransaction instance")

        more_atxs_to_verify = partial_verify_asset_transaction(atx)
        if more_atxs_to_verify == nil # Validation failed - return immediately
          return false
        elsif more_atxs_to_verify.size == 0 # atx is fully verifiable (issue-only or we used cached parents), remove it from the list
          
          # outputs may not be all verified because they can be transfers with cached verified inputs.
          # so we need to verify local balance and apply asset ids from inputs to outputs
          if !verify_transfers(atx) 
            return false
          end

          if i == 0 # that was the topmost transaction, we are done.
            return true
          end

          @source.asset_transaction_was_verified(atx)
          atx_stack.delete_at(i)
          i -= 1
          # If this is was the last parent to check, then the previous item would be :parents marker
          # Once we validate the child behind that marker, we might have another child or the marker again.
          # Unroll the stack until the previous item is not a child with all parents verified.
          while (child_atx = atx_stack[i]) == :parents
            BTC::Invariant(i >= 1, ":parents marker should be preceded by an asset transaction")
            atx_stack.delete_at(i)
            i -= 1
            child_atx = atx_stack.delete_at(i)

            # Now all inputs are verified, we only need to verify the transfer outputs against them.
            # This will make outputs verified for the later transactions (earlier in the list).
            if !verify_transfers(child_atx)
              return false
            end

            # Now transaction is fully verified.
            # Source can cache it if needed.
            @source.asset_transaction_was_verified(child_atx)

            if i == 0 # this was the topmost child, return
              return true
            end
            i -= 1
          end
        else
          # we have more things to verify - dig inside these transactions
          # Start with the last one so once any tx is verifed, we can move back and color inputs of the child transaction.
          atx_stack.insert(i+1, :parents, *more_atxs_to_verify)
          max_size = atx_stack.size if atx_stack.size > max_size
          j = i
          i += more_atxs_to_verify.size + 1
        end
      end
      return true
    end

    def color_transaction_inputs(atx)
      atx.inputs.each do |ain|
        if !ain.verified?
          prev_atx = ain.previous_asset_transaction
          BTC::Invariant(!!prev_atx, "Must have previous asset transaction")
          if !prev_atx.verified?
            #puts "\n Prev ATX not fully verified: #{prev_atx.inspect} -> input #{ain.index} of #{atx.inspect}"
          end
          BTC::Invariant(prev_atx.verified?, "Must have previous asset transaction outputs fully verified")
          output = prev_atx.outputs[ain.transaction_input.previous_index]
          BTC::Invariant(output && output.verified?, "Must have a valid reference to a previous verified output")
          # Copy over color information. The output can be colored or uncolored.
          ain.asset_id = output.asset_id
          ain.value = output.value
          ain.verified = true
        end
      end
    end


    # Returns a list of asset transactions remaining to verify.
    # Returns an empty array if verification succeeded and there is nothing more to verify.
    # Returns `nil` if verification failed.
    def partial_verify_asset_transaction(asset_transaction)
      raise ArgumentError, "Asset Transaction is missing" if !asset_transaction

      # 1. Verify issuing transactions and collect transfer outputs
      cache_transactions do
        if !verify_issues(asset_transaction)
          return nil
        end

        # No transfer outputs, this transaction is verified.
        # If there are assets on some inputs, they are destroyed.
        if asset_transaction.transfer_outputs.size == 0
          # We keep inputs unverified to indicate that they were not even processed.
          return []
        end

        # 2. Fetch parent transactions to verify.
        # * Verify inputs from non-OpenAsset transactions.
        # * Return OA transactions for verification.
        # * Link each input to its OA transaction output.
        prev_unverified_atxs_by_hash = {}
        asset_transaction.inputs.each do |ain|
          txin = ain.transaction_input
          # Ask source if it has a cached verified transaction for this input.
          prev_atx = @source.verified_asset_transaction_for_hash(txin.previous_hash)
          if prev_atx
            BTC::Invariant(prev_atx.verified?, "Cached verified tx must be fully verified")
          end
          prev_atx ||= prev_unverified_atxs_by_hash[txin.previous_hash]
          if !prev_atx
            prev_tx = transaction_for_input(txin)
            if !prev_tx
              Diagnostics.current.add_message("Failed to load previous transaction for input #{ain.index}: #{txin.previous_id}")
              return nil
            end
            begin
              prev_atx = AssetTransaction.new(transaction: prev_tx)
              prev_unverified_atxs_by_hash[prev_atx.transaction_hash] = prev_atx
            rescue FormatError => e
              # Previous transaction is not a valid Open Assets transaction,
              # so we mark the input as uncolored and verified as such.
              ain.asset_id = nil
              ain.value = nil
              ain.verified = true
            end
          end
          # Remember a reference to this transaction so we can validate the whole `asset_transaction` when all previous ones are set and verified.
          ain.previous_asset_transaction = prev_atx
        end # each input

        # Return all unverified transactions.
        # Note: this won't include the already verified one.
        prev_unverified_atxs_by_hash.values
      end
    end

    # Attempts to verify issues. Fetches parent transactions to determine AssetID.
    # Returns `true` if verified all issue outputs.
    # Returns `false` if previous tx defining AssetID is not found.
    def verify_issues(asset_transaction)
      previous_txout = nil # fetch only when we have > 0 issue outputs
      asset_transaction.outputs.each do |aout|
        if !aout.verified?
          if aout.value && aout.value > 0
            if aout.issue?
              previous_txout ||= transaction_output_for_input(asset_transaction.inputs[0].transaction_input)
              if !previous_txout
                Diagnostics.current.add_message("Failed to assign AssetID to issue output #{aout.index}: can't find output for input #0")
                return false
              end
              aout.asset_id = AssetID.new(script: previous_txout.script, network: self.network)
              # Output issues some known asset and amount and therefore it is verified.
              aout.verified = true
            else
              # Transfer outputs must be matched with known asset ids on the inputs.
            end
          else
            # Output without a value is uncolored.
            aout.asset_id = nil
            aout.value = nil
            aout.verified = true
          end
        end
      end
      true
    end # verify_issues

    # Attempts to verify transfer transactions assuming all inputs are verified.
    # Returns `true` if all transfers are verified (also updates `verified` and `asset_id` on them).
    # Returns `false` if any transfer is invalid or some inputs are not verified.
    def verify_transfers(asset_transaction)
      # Do not verify colors on inputs if no transfers occur. 
      # Typically it's an issuance tx. If there are assets on inputs, they are destroyed.
      if asset_transaction.transfer_outputs.size == 0
        return true
      end

      color_transaction_inputs(asset_transaction)

      current_asset_id = nil

      inputs = asset_transaction.inputs.dup
      current_asset_id = nil
      current_input = nil
      current_input_remainder = 0

      asset_transaction.outputs.each do |aout|
        # Only check outputs that can be colored (value > 0) and are transfer outputs (after the marker)
        if aout.has_value? && !aout.marker? && !aout.issue?

          aout.asset_id = nil
          remaining_value = aout.value

          # Try to fill in the output with available inputs.
          while remaining_value > 0

            BTC::Invariant((current_input_remainder == 0) ? (current_input == nil) : true,
              "Remainder must be == 0 only when current_input is nil")

            BTC::Invariant((current_input_remainder > 0) ? (current_input && current_input.colored?) : true,
              "Remainder must be > 0 only when transfer input is colored")

            current_input ||= inputs.shift

            # skip uncolored inputs
            while current_input && !current_input.colored?
              current_input = inputs.shift
            end

            if !current_input
              Diagnostics.current.add_message("Failed to assign AssetID to transfer output #{aout.index}: not enough colored inputs (#{remaining_value} missing for output #{aout.index}).")
              return false
            end

            # Need to consume aout.value units from inputs and extract the asset ID
            if !current_input.verified?
              Diagnostics.current.add_message("Failed to assign AssetID to transfer output #{aout.index}: input #{current_input.index} is not verified.")
              return false
            end

            # Make sure asset ID matches.
            # If output gets assigned units from 2 or more inputs, all asset ids must be the same.
            if !aout.asset_id
              aout.asset_id = current_input.asset_id
            else
              if aout.asset_id != current_input.asset_id
                Diagnostics.current.add_message("Failed to assign AssetID to transfer output #{aout.index}: already assigned another AssetID.")
                return false
              end
            end

            # If we have remainder from the previous output, use it.
            # Otherwise use the whole input's value.
            qty = if current_input_remainder > 0
              current_input_remainder
            else
              current_input.value
            end

            if qty <= remaining_value
              remaining_value -= qty
              # choose next input, clear remainder.
              current_input_remainder = 0
              current_input = nil
            else
              current_input_remainder = qty - remaining_value
              remaining_value = 0
              # keep the current input to use with `current_input_remainder` in the next output
            end
          end # filling in the output

          aout.verified = true

          BTC::Invariant(aout.verified && aout.asset_id && aout.value > 0, "Transfer output should be fully verified")
        end # only transfer outputs with value > 0
      end # each output

      # Some inputs may have remained. If those have some assets, they'll be destroyed.
      if current_input_remainder > 0
        Diagnostics.current.add_message("Warning: #{current_input_remainder} units left over from input #{current_input.index} will be destroyed.")
      end

      while current_input = inputs.shift
        if current_input.colored?
          Diagnostics.current.add_message("Warning: #{current_input.value} units from input #{current_input.index} will be destroyed.")
        end
      end

      return true
    end # verify_transfers

    # scans forward and validates every AssetTransaction on the way.
    def discover_asset(asset_id: nil)
      # TODO: ...
    end


    protected

    def cache_transactions(&block)
      begin
        @cached_txs_depth ||= 0
        @cached_txs_depth += 1
        @cached_txs ||= {}
        result = yield
      ensure
        @cached_txs_depth -= 1
        @cached_txs = nil if @cached_txs_depth <= 0
      end
      result
    end

    def transaction_for_input(txin)
      transaction_for_hash(txin.previous_hash)
    end

    def transaction_output_for_input(txin)
      tx = transaction_for_input(txin)
      if tx
        tx.outputs[txin.previous_index]
      else
        nil
      end
    end

    def transaction_for_hash(hash)
      if @cached_txs && (tx = @cached_txs[hash])
        return tx
      end
      tx = @source.transaction_for_hash(hash)
      if @cached_txs && tx
        @cached_txs[tx.transaction_hash] = tx
      end
      tx
    end
  end

  ::BTC::AssetTransactionInput # make sure AssetTransaction is defined
  class AssetTransactionInput
    attr_accessor :previous_asset_transaction
  end

  module AssetProcessorSource

    # Override this method if you can provide already verified transaction.
    def verified_asset_transaction_for_hash(hash)
      nil
    end

    # Override this to cache verified asset transaction.
    def asset_transaction_was_verified(atx)
      nil
    end

    # Override this to provide a transaction with a given hash.
    # If transaction is not found or not available, return nil.
    # This may cause asset transaction remain unverified.
    def transaction_for_hash(hash)
      raise "Not Implemented"
    end
  end
end
