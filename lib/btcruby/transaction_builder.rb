# Note: additional files are required in the bottom of the file.

module BTC
  # TransactionBuilder allows to build arbitrary transactions using any source of
  # unspent outputs and deferring signing to the user if needed.
  # Features:
  # - full spending feature vs. multi-output spending feature.
  # - BIP44-friendly spending algorithm by default, but you can opt out.
  # - flexible change/dust controls
  # - flexible inputs API
  # - flexible signing ability
  # - support for compressed/uncompressed keys
  # - support for pay-to-pubkey scripts

  # TransactionBuilder composes and optionally sings a transaction.
  class TransactionBuilder

    # Network to validate provided addresses against.
    # Default value is `Network.default`.
    attr_accessor :network

    # An array of BTC::TransactionOutput instances specifying how many coins to spend and how.
    # If the array is empty, all unspent outputs are spent to the change address.
    attr_accessor :outputs

    # Change address (base58-encoded string or BTC::Address).
    # Must be specified, but may not be used if change is too small.
    attr_accessor :change_address

    # Addresses from which to fetch the inputs.
    # Could be base58-encoded address or BTC::Address instances.
    # If any address is a WIF, the corresponding input will be automatically signed with SIGHASH_ALL.
    # Otherwise, the signature_script in the input will be set to output script from unspent output.
    attr_accessor :input_addresses

    # Prepended unspent outputs with valid `index` and `transaction_hash` attributes.
    # These will be included before some optional unspent outputs.
    attr_accessor :prepended_unspent_outputs

    # Actual available BTC::TransactionOutput's to spend.
    # If not specified, builder will fetch and remember unspent outputs using `provider`.
    # Only necessary inputs will be selected for spending.
    # If TransactionOutput#confirmations attribute is not nil, outputs are sorted
    # from oldest to newest, unless #keep_unspent_outputs_order is set to true.
    attr_accessor :unspent_outputs
    
    # Array of non-published transactions, which outputs can be consumed.
    attr_accessor :parent_transactions

    # Provider of the unspent outputs.
    # If not specified, `unspent_outputs` must be provided.
    attr_accessor :provider

    # Signer for the inputs.
    # If not provided, inputs will be left unsigned.
    attr_accessor :signer

    # Miner's fee per kilobyte (1000 bytes).
    # Default is Transaction::DEFAULT_FEE_RATE
    attr_accessor :fee_rate

    # Minimum amount of change below which transaction is not composed.
    # If change amount is non-zero and below this value, more unspent outputs are used.
    # If change amount is zero, change output is not even created and this attribute is not used.
    # Default value equals fee_rate.
    attr_accessor :minimum_change

    # Amount of change that can be forgone as a mining fee if there are no more
    # unspent outputs available. If equals zero, no amount is allowed to be forgone.
    # Default value equals minimum_change.
    # This means builder will never fail with "insufficient funds" just because it could not
    # find enough unspents for big enough change. In worst case it will forgo the change
    # as a part of the mining fee. Set to 0 to avoid wasting a single satoshi.
    attr_accessor :dust_change

    # If true, does not sort unspent_outputs by confirmations number.
    # Default is false, but order will be preserved if #confirmations attribute is nil.
    attr_accessor :keep_unspent_outputs_order

    # Introspection methods. Used by Provider during `build` process.

    # Public addresses used on the inputs.
    # Composed by converting all `WIF` instance in `input_addresses` to corresponding public addresses.
    attr_reader :public_addresses

    # A total amount in satoshis to be spent in all outputs (not including change output).
    # If equals `nil`, all available unspent outputs for the public_address are expected to be returned
    # ("swiping the keys").
    attr_reader :outputs_amount

    # A total size of all outputs in bytes (including change output).
    attr_reader :outputs_size


    # Implementation of the attributes declared above
    # ===============================================

    def network
      @network ||= Network.default
    end

    def input_addresses=(addresses)
      @input_addresses = addresses
      # Normalize addresses to make them all BTC::Address instances
      if @input_addresses
        @input_addresses = @input_addresses.map do |addr|
          BTC::Address.parse(addr).tap do |a|
            if !a.is_a?(BTC::BitcoinPaymentAddress) && !a.is_a?(WIF)
              raise ArgumentError, "Expected BitcoinPaymentAddress and WIF instances"
            end
            if a.network != self.network
              raise ArgumentError, "Network mismatch. Expected input address for #{self.network.name}."
            end
          end
        end
      end
      @unspent_outputs = nil
    end

    def unspent_outputs
      # Lazily fetch unspent outputs using data provider block.
      @unspent_outputs ||= self.internal_provider.unspent_outputs(self)
    end

    def provider=(provider)
      @provider = provider
      @unspent_outputs = nil
    end
    
    def internal_provider
      @internal_provider ||= (self.provider || Provider.new{|txb| []})
    end
    
    def change_address=(change_address)
      if change_address
        addr = BTC::BitcoinPaymentAddress.parse(change_address)
        if addr.network != self.network
          raise ArgumentError, "Network mismatch. Expected change address for #{self.network.name}."
        end
        @change_address = addr
      else
        @change_address = nil
      end
    end

    def fee_rate
      @fee_rate ||= Transaction::DEFAULT_FEE_RATE
    end

    def minimum_change
      @minimum_change || self.fee_rate
    end

    def dust_change
      @dust_change || self.minimum_change
    end

    def public_addresses
      (@input_addresses || []).map{|a| a.public_address }
    end

    def outputs_amount
      if !self.outputs || self.outputs.size == 0
        return nil
      end
      self.outputs.inject(0){|sum, o| sum + o.value }
    end

    def outputs_size
      raise ArgumentError, "Change address must be specified" if !self.change_address
      (self.outputs || []).inject(0){|sum, output| sum + output.data.bytesize } +
      TransactionOutput.new(value:MAX_MONEY, script: self.change_address.script).data.bytesize
    end

    # Attempts to build a transaction
    def build

      if !self.change_address
        raise MissingChangeAddressError
      end

      result = Result.new

      add_input_for_utxo = proc do |utxo|
        raise ArgumentError, "Unspent output must contain index" if !utxo.index
        raise ArgumentError, "Unspent output must contain transaction_hash" if !utxo.transaction_hash

        if !self.internal_provider.consumed_unspent_output?(utxo)
          self.internal_provider.consume_unspent_output(utxo)

          result.inputs_amount += utxo.value
          txin = TransactionInput.new(
                                      previous_hash: utxo.transaction_hash,
                                      previous_index: utxo.index,
                                      # put the output script here so the signer knows which key to use.
                                      signature_script: utxo.script)
          txin.transaction_output = utxo
          result.transaction.add_input(txin)
        else
          # UTXO was already consumed possibly by another Tx Builder sharing the same provider.
        end
      end

      # If no outputs are specified, spend all utxos to a change address, minus the mining fee.
      if (self.outputs || []).size == 0
        result.inputs_amount = 0

        (self.prepended_unspent_outputs || []).each(&add_input_for_utxo)
        (self.unspent_outputs || []).each(&add_input_for_utxo)

        if result.transaction.inputs.size == 0
          raise MissingUnspentOutputsError, "Missing unspent outputs"
        end

        # Value will be determined after computing the fee
        change_output = TransactionOutput.new(value: 0, script: self.change_address.public_address.script)
        result.transaction.add_output(change_output)

        result.fee = compute_fee_for_transaction(result.transaction, self.fee_rate)
        result.outputs_amount = result.inputs_amount - result.fee
        result.change_amount = 0

        # Check if inputs cover the fees
        if result.outputs_amount < 0
          raise InsufficientFundsError
        end

        # Warn if the output amount is relatively small.
        if result.outputs_amount < result.fee
          Diagnostics.current.add_message("BTC::TransactionBuilder: Warning! Spending all unspent outputs returns less than a mining fee. (#{result.outputs_amount} < #{result.fee})")
        end

        # Set the output value as needed
        result.transaction.outputs[0].value = result.outputs_amount

        # For each address that is a WIF, locate the matching input and sign it.
        attempt_to_sign_transaction(result)

        return result
      end # if no specific outputs required

      # We are having one or more outputs (e.g. normal payment)
      # Need to find appropriate unspents and compose a transaction.

      # Prepare all outputs.
      # result.outputs_amount will also contain a fee after it's calculated.
      (self.outputs || []).each do |txout|
        result.outputs_amount += txout.value
        result.transaction.add_output(txout)
      end

      # We'll determine final change value depending on inputs.
      # Setting default to MAX_MONEY will protect against a bug when we fail to update the amount and
      # spend unexpected amount on mining fees.
      change_output = TransactionOutput.new(value: MAX_MONEY, script: self.change_address.public_address.script)
      result.transaction.add_output(change_output)

      mandatory_utxos = (self.prepended_unspent_outputs || []).to_a.dup

      # We have specific outputs with specific amounts, so we need to select the best amount of coins.
      # To play nice with BIP32/BIP44 change addresses (that need to monitor an increasing amount of addresses),
      # we'll spend oldest outputs first and will add more and more newer outputs until we cover fees
      # and change output is either zero or above the dust limit.
      # If `confirmations` attribute is nil, order is preserved.
      utxos = self.unspent_outputs || []
      if self.keep_unspent_outputs_order
        sorted_utxos = utxos.to_a.dup
      else
        sorted_utxos = utxos.to_a.sort_by{|txout| -(txout.confirmations || -1) } # oldest first
      end
      
      if self.parent_transactions
        # Can repeat some outputs in mandatory_utxos or sorted_utxos, 
        # but double-spending will be prevented by provider.
        self.parent_transactions.each do |parenttx|
          sorted_utxos += parenttx.outputs
        end
      end
      
      all_utxos = (sorted_utxos + mandatory_utxos)

      while true
        if (sorted_utxos.size + mandatory_utxos.size) == 0
          raise InsufficientFundsError
        end

        utxo = nil
        while (sorted_utxos.size + mandatory_utxos.size) > 0
          utxo = if mandatory_utxos.size > 0
            mandatory_utxos.shift
          else
            sorted_utxos.shift
          end 
          if utxo.value > 0 &&
            !utxo.script.op_return_script? &&
            !self.internal_provider.consumed_unspent_output?(utxo)
            self.internal_provider.consume_unspent_output(utxo)
            break
          else
            #puts "CONSUMED UTXO, SKIPPING: #{utxo.transaction_id}:#{utxo.index} (#{utxo.value})"
            # Continue reading utxos to find one that is not consumed yet.
            utxo = nil
          end
        end
        
        if !utxo
          # puts "ALL UTXOS:"
          # all_utxos.each do |utxo|
          #   puts "--> #{utxo.transaction_id}:#{utxo.index} (#{utxo.value})"
          # end
          raise InsufficientFundsError
        end
        
        result.inputs_amount += utxo.value

        raise ArgumentError, "Transaction hash must be non-nil in unspent output" if !utxo.transaction_hash
        raise ArgumentError, "Index must be non-nil in unspent output" if !utxo.index

        txin = TransactionInput.new(previous_hash: utxo.transaction_hash,
                                    previous_index: utxo.index,
                                    # put the output script here so the signer knows which key to use.
                                    signature_script: utxo.script)
        txin.transaction_output = utxo
        result.transaction.add_input(txin)

        # Do not check the result before we included all the mandatory utxos.
        if mandatory_utxos.size == 0
          # Before computing the fee, quick check if we have enough inputs to cover the outputs.
          # If not, go and add one more utxo before wasting time computing fees.
          if result.inputs_amount >= result.outputs_amount
            fee = compute_fee_for_transaction(result.transaction, self.fee_rate)

            change = result.inputs_amount - result.outputs_amount - fee

            if change >= self.minimum_change

              # We have a big enough change, set missing values and return.

              change_output.value = change
              result.change_amount = change
              result.outputs_amount += change
              result.fee = fee
              attempt_to_sign_transaction(result)
              return result

            elsif change > self.dust_change && change < self.minimum_change

              # We have a shitty change: not small enough to forgo, not big enough to be useful.
              # Try adding more utxos on the next cycle (or fail if no more utxos are available).

            elsif change >= 0 && change <= self.dust_change
              # This also includes the case when change is exactly zero satoshis.
              # Remove the change output, keep existing outputs_amount, set fee and try to sign.
              result.transaction.outputs = result.transaction.outputs[0, result.transaction.outputs.size - 1]
              result.change_amount = 0
              result.fee = fee
              attempt_to_sign_transaction(result)
              return result

            else
              # Change is negative, we need more funds for this transaction.
              # Try adding more utxos on the next cycle.

            end

          end # if inputs_amount >= outputs_amount
        end # if no more mandatory outputs to add
      end # while true
    end # build_transaction

    private

    # Helper to compute total fee for a given transaction.
    # Simulates signatures to estimate final size.
    def compute_fee_for_transaction(tx, fee_rate)
      # Compute fees for this tx by composing a tx with properly sized dummy signatures.
      simulated_tx = tx.dup
      simulated_tx.inputs.each do |txin|
        txout_script = txin.transaction_output.script
        txin.signature_script = txout_script.simulated_signature_script(strict: false) || txout_script
      end
      return simulated_tx.compute_fee(fee_rate: fee_rate)
    end

    def attempt_to_sign_transaction(result)
      # By default, all inputs are marked to be signed.
      result.unsigned_input_indexes = (0...(result.transaction.inputs.size)).to_a

      return if result.transaction.inputs.size == 0

      fill_dict_with_key = proc do |dict, key|
        ck = key.compressed_key
        uck = key.uncompressed_key
        p2pkh_compressed_script = PublicKeyAddress.new(public_key: ck.public_key).script
        p2pkh_uncompressed_script = PublicKeyAddress.new(public_key: uck.public_key).script
        p2pk_compressed_script = Script.new << ck.public_key << OP_CHECKSIG
        p2pk_uncompressed_script = Script.new << uck.public_key << OP_CHECKSIG
        dict[p2pkh_compressed_script.data]   = ck
        dict[p2pkh_uncompressed_script.data] = uck
        dict[p2pk_compressed_script.data]    = ck
        dict[p2pk_uncompressed_script.data]  = uck
      end

      # Arrange WIFs with script_data => Key
      keys_for_script_data = (@input_addresses || []).find_all{|a|a.is_a?(WIF)}.inject({}) do |dict, wif|
        # We support two kinds of scripts: p2pkh (modern style) and p2pk (old style)
        # For each of these we support compressed and uncompressed pubkeys.
        key = wif.key
        fill_dict_with_key.call(dict, key)
        dict
      end

      # We should group all inputs by their output script.
      # For each group, try to find a key among WIFs, or ask the provider for a key.
      # If key is not available or the script is not a standard one, ask signer for a raw signature_script.
      grouped_inputs = result.transaction.inputs.group_by do |txin|
        txin.signature_script.data
      end

      grouped_inputs.each do |script_data, inputs|
        first_input = inputs.first
        script = first_input.signature_script
        key = nil # will be used only for standard p2pk, p2pkh scripts.
        if script.p2pk? || script.p2pkh?
          address = script.standard_address(network: self.network)
          key = keys_for_script_data[script_data]
          if !key && (key = self.signer ? self.signer.signing_key_for_output(output: first_input.transaction_output, address: address) : nil)
            if !key.private_key
              raise ArgumentError, "Provided BTC::Key must contain the private key"
            end
            fill_dict_with_key.call(keys_for_script_data, key) # so we get the properly compressed version for the current script.
            key = keys_for_script_data[script_data]
            # Note: if incorrect key was provided, we won't find a matching script data.
            if !key
              raise ArgumentError, "Key does not match the output"
            end
          end
        end

        # If we finally have a key, it's of correct compression and only for p2pk, p2pkh scripts.
        if key
          hashtype = SIGHASH_ALL
          encoded_hashtype = WireFormat.encode_uint8(hashtype)

          inputs.each do |txin|
            output_script = txin.signature_script.dup
            sighash = result.transaction.signature_hash(input_index: txin.index, output_script: output_script, hash_type: hashtype)
            if script.p2pk?
              txin.signature_script = Script.new << (key.ecdsa_signature(sighash) + encoded_hashtype)
              result.unsigned_input_indexes.delete(txin.index)
            elsif script.p2pkh?
              txin.signature_script = Script.new << (key.ecdsa_signature(sighash) + encoded_hashtype) << key.public_key
              result.unsigned_input_indexes.delete(txin.index)
            else
              BTC::Invariant(false, "All txins are expected to be of the same type")
              # Unknown script, leave unsigned.
            end
          end
        else # no keys - ask signer
          inputs.each do |txin|
            sigscript = self.signer ? self.signer.signature_script_for_input(input: txin, output: txin.transaction_output) : nil
            if sigscript
              txin.signature_script = sigscript
              result.unsigned_input_indexes.delete(txin.index)
            end
          end
        end
      end
    end # attempt_to_sign_transaction


  end
end

require_relative 'transaction_builder/errors.rb'
require_relative 'transaction_builder/result.rb'
require_relative 'transaction_builder/provider.rb'
require_relative 'transaction_builder/signer.rb'

if $0 == __FILE__

  # require_relative '../btcruby.rb'
  # require 'pp'
  # include BTC
  #
  # def mock_keys
  #   @mock_keys ||= [
  #     Key.random,
  #     Key.random
  #   ]
  # end
  #
  # def mock_addresses
  #   mock_keys.map{|k| PublicKeyAddress.new(public_key: k.public_key) }
  # end
  #
  # def mock_utxos
  #   scripts = mock_addresses.map{|a| a.script }
  #   (0...100).map do |i|
  #     TransactionOutput.new(value:  1000_00, script: scripts[i % scripts.size])
  #   end
  # end
  #
  # @builder = TransactionBuilder.new
  # @all_utxos = mock_utxos
  # @builder.input_addresses = mock_addresses
  # @builder.provider = TransactionBuilder::Provider.new do |txb|
  #   scripts = txb.public_addresses.map{|a| a.script }.uniq
  #   @all_utxos.find_all{|utxo| scripts.include?(utxo.script) }
  # end
  #
  # @builder.change_address = Address.parse("1CBtcGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG")
  #
  # tx = @builder.transaction
  #
  # puts tx.inspect


end

