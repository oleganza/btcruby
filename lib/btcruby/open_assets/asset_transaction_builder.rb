# Note: additional files are required in the bottom of the file.

# High-level Transaction Builder for OpenAssets protocol.
# https://github.com/OpenAssets/open-assets-protocol/blob/master/specification.mediawiki
module BTC
  # TODO:
  # - provide Asset ID(s) as input, or raw AssetTransactionInput objects
  # - provide raw unspents to pay mining fees
  # - provide asset change address
  # - provide btc change address
  # - provide issuance API, transfer API, payment API (plain btc outputs)
  # Use TransactionBuilder internally.
  class AssetTransactionBuilder

    # Network to validate provided addresses against.
    # Default value is `Network.default`.
    attr_accessor :network

    # Must be a subclass of a BTC::BitcoinPaymentAddress
    attr_accessor :bitcoin_change_address

    # Must be a subclass of a BTC::AssetAddress
    attr_accessor :asset_change_address

    # Enumerable yielding BTC::TransactionOutput instances with valid `transaction_hash` and `index` properties.
    # If not specified, `bitcoin_unspent_outputs_provider` is used if possible.
    attr_accessor :bitcoin_unspent_outputs

    # Enumerable yielding BTC::AssetTransactionOutput instances with valid `transaction_hash` and `index` properties.
    attr_accessor :asset_unspent_outputs

    # Provider of the pure bitcoin unspent outputs adopting TransactionBuilder::Provider.
    # If not specified, `bitcoin_unspent_outputs` must be provided.
    attr_accessor :bitcoin_provider

    # Provider of the pure bitcoin unspent outputs adopting AssetTransactionBuilder::Provider.
    # If not specified, `asset_unspent_outputs` must be provided.
    attr_accessor :asset_provider

    # TransactionBuilder::Signer for all the inputs (bitcoins and assets).
    # If not provided, inputs will be left unsigned and `result.unsigned_input_indexes` will contain indexes of these inputs.
    attr_accessor :signer

    # Miner's fee per kilobyte (1000 bytes).
    # Default is Transaction::DEFAULT_FEE_RATE
    attr_accessor :fee_rate

    # Metadata to embed in the marker output. Default is nil (empty string).
    attr_accessor :metadata

    def initialize
    end

    def asset_unspent_outputs=(unspents)
      self.asset_provider = Provider.new{|atxbuilder| unspents }
    end

    # Adds an issuance of some assets.
    # If `script` is specified, it is used to create an intermediate base transaction.
    # If `output` is specified, it must be a valid spendable output with `transaction_id` and `index`.
    #   It can be regular TransactionOutput or verified AssetTransactionOutput.
    # `amount` must be > 0 - number of units to be issued
    def issue_asset(source_script: nil, source_output: nil,
                    amount: nil,
                    script: nil, address: nil)
      raise ArgumentError, "Either `source_script` or `source_output` must be specified" if !source_script && !source_output
      raise ArgumentError, "Both `source_script` and `source_output` cannot be specified" if source_script && source_output
      raise ArgumentError, "Either `script` or `address` must be specified" if !script && !address
      raise ArgumentError, "Both `script` and `address` cannot be specified" if script && address
      raise ArgumentError, "Amount must be greater than zero" if !amount || amount <= 0
      if source_output && (!source_output.index || !source_output.transaction_hash)
        raise ArgumentError, "If `source_output` is specified, it must have valid `transaction_hash` and `index` attributes"
      end
      script ||= AssetAddress.parse(address).script

      # Ensure source output is a verified asset output.
      if source_output
        if source_output.is_a?(AssetTransactionOutput)
          raise ArgumentError, "Must be verified asset output to spend" if !source_output.verified?
        else
          source_output = AssetTransactionOutput.new(transaction_output: source_output, verified: true)
        end
      end

      # Set either the script or output only once.
      # All the remaining issuances must use the same script or output.
      if !self.issuing_asset_script && !self.issuing_asset_output
        self.issuing_asset_script = source_script
        self.issuing_asset_output = source_output
      else
        if self.issuing_asset_script != source_script || self.issuing_asset_output != source_output
          raise ArgumentError, "Can't issue more assets from a different source script or source output"
        end
      end
      self.issued_assets << {amount: amount, script: script}
    end

    # Adds a transfer output.
    # May override per-builder unspents/provider/change address to allow multi-user swaps.
    def transfer_asset(asset_id: nil,
                       amount: nil,
                       script: nil, address: nil,
                       provider: nil, unspent_outputs: nil, change_address: nil)
      raise ArgumentError, "AssetID must be provided" if !asset_id
      raise ArgumentError, "Either `script` or `address` must be specified" if !script && !address
      raise ArgumentError, "Both `script` and `address` cannot be specified" if script && address
      raise ArgumentError, "Amount must be greater than zero" if !amount || amount <= 0

      provider = Provider.new{|atxbuilder| unspent_outputs } if unspent_outputs
      change_address = AssetAddress.parse(change_address) if change_address

      asset_id = AssetID.parse(asset_id)
      script ||= AssetAddress.parse(address).script

      self.transferred_assets << {asset_id: asset_id, amount: amount, script: script, provider: provider, change_address: change_address}
    end

    # Adds a normal payment output. Typically used for transfer
    def send_bitcoin(output: nil, amount: nil, script: nil, address: nil)
      if !output
        raise ArgumentError, "Either `script` or `address` must be specified" if !script && !address
        raise ArgumentError, "Amount must be specified (>= 0)" if (!amount || amount < 0)
        script ||= address.public_address.script if address
        output = TransactionOutput.new(value: amount, script: script)
      end
      self.bitcoin_outputs << output
    end

    def bitcoin_change_address=(addr)
      @bitcoin_change_address = BitcoinPaymentAddress.parse(addr)
    end

    def asset_change_address=(addr)
      @asset_change_address = AssetAddress.parse(addr)
    end

    def build

      validate_bitcoin_change_address!
      validate_asset_change_address!

      result = Result.new

      # We don't count assets_cost because outputs of these txs
      # will be consumed in the next transaction. Only add the fees.
      if self.issuing_asset_script
        issuing_tx, unsigned_input_indexes = make_transaction_for_issues
        result.fee = issuing_tx.fee
        result.transactions << issuing_tx
        result.unsigned_input_indexes << unsigned_input_indexes
        self.issuing_asset_output = AssetTransactionOutput.new(transaction_output: issuing_tx.outputs.first, verified: true)
      end

      # Prepare the target transaction
      txbuilder = make_transaction_builder
      if result.transactions.size > 0
        txbuilder.parent_transactions = [result.transactions.last]
      end
      txbuilder.prepended_unspent_outputs ||= []
      txbuilder.outputs = []

      # Add issuance input and outputs first.

      consumed_asset_outputs = [] # used in inputs
      issue_outputs = []
      transfer_outputs = []

      if self.issued_assets.size > 0
        txbuilder.prepended_unspent_outputs << self.issuing_asset_output.transaction_output
        self.issued_assets.each do |issue|
          atxo = make_asset_transaction_output(asset_id: issuing_asset_id, amount: issue[:amount], script: issue[:script])
          issue_outputs << atxo
        end
      end

      # Move all transfers of the asset ID used on the issuing output to the top of the list.
      asset_id_on_the_issuing_input = self.issuing_asset_output ? self.issuing_asset_output.asset_id : nil
      if asset_id_on_the_issuing_input
        aid = asset_id_on_the_issuing_input.to_s
        self.transferred_assets = self.transferred_assets.sort do |a,b|
          # move the asset id used in the issue input to the top
          if a[:asset_id].to_s == aid
            -1
          elsif b[:asset_id] == aid
            1
          else
            0 # keep the order
          end
        end
      end

      consumed_outpoints = {} # "txid:index" => true

      self.transferred_assets.each do |transfer| # |aid,transfers|
        asset_id = transfer[:asset_id]
        transfers = [transfer]
        amount_required = 0
        amount_provided = 0
        if asset_id_on_the_issuing_input.to_s == asset_id.to_s
          amount_provided = self.issuing_asset_output.value
        end

        atxo = make_asset_transaction_output(asset_id: transfer[:asset_id],
                                             amount: transfer[:amount],
                                             script: transfer[:script])
        amount_required += atxo.value
        transfer_outputs << atxo

        # Fill in enough unspent assets for this asset_id.
        # Use per-transfer provider if it's specified. Otherwise use global provider.
        provider = transfer[:provider] || self.asset_provider
        unspents = provider.asset_unspent_outputs(asset_id: asset_id, amount: amount_required).dup

        while amount_provided < amount_required
          autxo = unspents.shift
          if !autxo
            raise InsufficientFundsError, "Not enough outputs for asset #{asset_id.to_s} (#{amount_provided} available < #{amount_required} required)"
          end
          if !consumed_outpoints[oid = autxo.transaction_output.outpoint_id]
            # Only apply outputs with matching asset ids.
            if autxo.asset_id == asset_id
              raise ArgumentError, "Must be verified asset outputs to spend" if !autxo.verified?
              consumed_outpoints[oid] = true
              amount_provided += autxo.value
              consumed_asset_outputs << autxo
              txbuilder.prepended_unspent_outputs << autxo.transaction_output
            end
          end
        end

        # If the difference is > 0, add a change output
        change = amount_provided - amount_required
        if change > 0
          # Use per-transfer change address if it's specified. Otherwise use global change address.
          change_addr = transfer[:change_address] || self.asset_change_address
          atxo = make_asset_transaction_output(asset_id: asset_id,
                                               amount: change,
                                               script: change_addr.script)
          transfer_outputs << atxo
        end

      end # each transfer

      # If we have an asset on the issuance input and it is never used in any transfer,
      # then we need to create a change output just for it.
      if asset_id_on_the_issuing_input && self.issuing_asset_output.value > 0
        if !self.transferred_assets.map{|dict| dict[:asset_id].to_s }.uniq.include?(asset_id_on_the_issuing_input.to_s)
          atxo = make_asset_transaction_output(asset_id: self.issuing_asset_output.asset_id,
                                               amount: self.issuing_asset_output.value,
                                               script: self.asset_change_address.script)
          transfer_outputs << atxo
        end
      end

      all_asset_outputs = (issue_outputs + transfer_outputs)
      result.assets_cost = all_asset_outputs.inject(0){|sum, atxo| sum + atxo.transaction_output.value }
      marker = AssetMarker.new(quantities: all_asset_outputs.map{|atxo| atxo.value }, metadata: self.metadata)

      # Now, add underlying issues, marker and transfer outputs
      issue_outputs.each do |atxo|
        txbuilder.outputs << atxo.transaction_output
      end
      txbuilder.outputs << marker.output
      transfer_outputs.each do |atxo|
        txbuilder.outputs << atxo.transaction_output
      end

      txresult = txbuilder.build
      tx = txresult.transaction
      atx = AssetTransaction.new(transaction: tx)

      BTC::Invariant(atx.outputs.size == all_asset_outputs.size + 1 + (txresult.change_amount > 0 ? 1 : 0),
        "Must have all asset outputs (with marker output and optional change output)");

      if txresult.change_amount > 0
        plain_change_output = atx.outputs.last
        BTC::Invariant(!plain_change_output.verified?, "Must have plain change output not verified");
        BTC::Invariant(!plain_change_output.asset_id, "Must have plain change output not have asset id");
        BTC::Invariant(!plain_change_output.value, "Must have plain change output not have asset amount");
        plain_change_output.verified = true # to match the rest of outputs.
      end

      # Provide color info for each input
      consumed_asset_outputs.each_with_index do |atxo, i|
        atx.inputs[i].asset_id = atxo.asset_id
        atx.inputs[i].value = atxo.value
        atx.inputs[i].verified = true
      end
      atx.inputs[consumed_asset_outputs.size..-1].each do |input|
        input.asset_id = nil
        input.value = nil
        input.verified = true
      end

      # Provide color info for each output
      issue_outputs.each_with_index do |aout1, i|
        aout = atx.outputs[i]
        aout.asset_id = aout1.asset_id
        aout.value = aout1.value
        aout.verified = true
      end
      atx.outputs[issue_outputs.size].verified = true # make marker verified
      offset = 1 + issue_outputs.size # +1 for marker
      transfer_outputs.each_with_index do |aout1, i|
        aout = atx.outputs[i + offset]
        aout.asset_id = aout1.asset_id
        aout.value = aout1.value
        aout.verified = true
      end
      offset = 1 + issue_outputs.size + transfer_outputs.size # +1 for marker
      atx.outputs[offset..-1].each do |aout|
        aout.asset_id = nil
        aout.value = nil
        aout.verified = true
      end

      if txresult.change_amount == 0
        atx.outputs.each do |aout|
          if !aout.marker?
            BTC::Invariant(aout.verified?, "Must be verified");
            BTC::Invariant(!!aout.asset_id, "Must have asset id");
            BTC::Invariant(aout.value && aout.value > 0, "Must have some asset amount");
          end
        end
      end

      result.unsigned_input_indexes << txresult.unsigned_input_indexes
      result.transactions << tx
      result.asset_transaction = atx

      result
    end

    # Helpers

    def issuing_asset_id
      @issuing_asset_id ||= AssetID.new(script: @issuing_asset_script || @issuing_asset_output.transaction_output.script)
    end

    def make_asset_transaction_output(asset_id: nil, amount: nil, script: nil)
      txout = make_output_for_asset_script(script)
      AssetTransactionOutput.new(transaction_output: txout, asset_id: asset_id, value: amount, verified: true)
    end

    def make_transaction_for_issues
      raise "Sanity check" if !self.issuing_asset_script
      txbuilder = make_transaction_builder
      txbuilder.outputs = [
        make_output_for_asset_script(self.issuing_asset_script)
      ]
      result = txbuilder.build
      [result.transaction, result.unsigned_input_indexes]
    end

    def make_output_for_asset_script(script)
      txout = BTC::TransactionOutput.new(value: MAX_MONEY, script: script)
      txout.value = txout.dust_limit
      raise RuntimeError, "Sanity check: txout value must not be zero" if txout.value <= 0
      txout
    end

    def make_transaction_builder
      txbuilder = TransactionBuilder.new
      txbuilder.change_address = self.bitcoin_change_address
      txbuilder.signer = self.signer
      txbuilder.provider = self.internal_bitcoin_provider
      txbuilder.unspent_outputs = self.bitcoin_unspent_outputs
      txbuilder.fee_rate = self.fee_rate
      txbuilder
    end

    def internal_bitcoin_provider
      @internal_bitcoin_provider ||= (self.bitcoin_provider || TransactionBuilder::Provider.new{|txb| []})
    end


    # Validation Methods

    def validate_bitcoin_change_address!
      addr = self.bitcoin_change_address
      raise ArgumentError, "Missing bitcoin_change_address" if !addr
      raise ArgumentError, "bitcoin_change_address must be an instance of BTC::Address" if !addr.is_a?(Address)
      raise ArgumentError, "bitcoin_change_address must not be an instance of BTC::AssetAddress" if addr.is_a?(AssetAddress)
    end

    def validate_asset_change_address!
      self.transferred_assets.each do |dict|
        addr = dict[:change_address] || self.asset_change_address
        raise ArgumentError, "Missing asset_change_address" if !addr
        raise ArgumentError, "asset_change_address must be an instance of BTC::AssetAddress" if !addr.is_a?(AssetAddress)
      end
    end

    protected
    attr_accessor :issuing_asset_script
    attr_accessor :issuing_asset_output
    attr_accessor :issued_assets
    attr_accessor :transferred_assets
    attr_accessor :bitcoin_outputs

    def issued_assets
      @issued_assets ||= []
    end

    def transferred_assets
      @transferred_assets ||= []
    end

    def bitcoin_outputs
      @bitcoin_outputs ||= []
    end

  end
end

require_relative 'asset_transaction_builder/errors.rb'
require_relative 'asset_transaction_builder/result.rb'
require_relative 'asset_transaction_builder/provider.rb'
