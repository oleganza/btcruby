# Implementation of OpenAssets protocol.
# https://github.com/OpenAssets/open-assets-protocol/blob/master/specification.mediawiki
module BTC

  # Wrapper around Transaction that stores info about assets on inputs and outputs.
  class AssetTransaction

    # Raw BTC::Transaction containing asset transfer
    attr_reader :transaction

    # List of AssetTransactionInput instances.
    attr_reader :inputs

    # List of AssetTransactionOutput instances.
    attr_reader :outputs

    # AssetMarker instance describing the transaction
    attr_reader :marker

    # Metadata stored in AssetMarker
    attr_reader :metadata

    # Identifier of the underlying Bitcoin transaction.
    attr_reader :transaction_hash
    attr_reader :transaction_id

    def initialize(transaction: nil, data: nil)
      if data && !transaction
        txdata, len = WireFormat.read_string(data: data, offset: 0)
        raise ArgumentError, "Invalid data: tx data" if !txdata
        transaction = Transaction.new(data: txdata)
        data = data[len..-1]
      end
      raise ArgumentError, "Missing transaction" if !transaction
      raise FormatError, "Transaction does not contain an AssetMarker" if !transaction.open_assets_transaction?
      raise FormatError, "Coinbase transactions cannot be AssetTransactions" if transaction.coinbase?
      raise FormatError, "Transactions with no inputs cannot be AssetTransactions" if transaction.inputs.size == 0

      @transaction = transaction

      # Extract the first marker output
      marker_output = transaction.outputs.find{|txout| txout.script.open_assets_marker? }
      @marker = AssetMarker.new(output: marker_output) # raises if marker is malformed

      # Create unverified inputs.
      @inputs = transaction.inputs.map do |txin|
        AssetTransactionInput.new(transaction_input: txin)
      end

      # Create unverified outputs for all outputs.
      @outputs = transaction.outputs.inject([]) do |array, txout|
        # note: other outputs looking like markers are allowed, so we check for the first one only.
        aout = AssetTransactionOutput.new(transaction_output: txout)
        if txout == marker_output
          aout.marker = true
          aout.verified = true
        else
          if (txout.index < marker_output.index)
            aout.issue = true
          else
            aout.transfer = true
          end
        end
        array << aout
      end

      # Check that the marker contains not more quantities than outputs available.
      # Marker output does not count and is not included in quantities list.
      if @marker.quantities.size > (@outputs.size - 1)
        raise FormatError, "OpenAssets marker specifies more quantities than colorable outputs available: #{@marker.quantities.size} > #{@outputs.size-1}."
      end

      # Fill in assets amounts for outputs (but keep them unverified).
      # Excessive outputs receive `nil` amount.
      @outputs.find_all{|o|!o.marker?}.each_with_index do |aout, i|
        aout.value = @marker.quantities[i]
      end

      # contains only color info about ins/outs
      if data
        offset = 0
        @inputs.each do |ain|
          offset = ain.parse_assets_data(data, offset: offset)
        end
        @outputs.each do |aout|
          if !aout.marker?
            offset = aout.parse_assets_data(data, offset: offset)
          end
        end
      end
    end

    # Serialized tx will have:
    # - raw tx data
    # - array of input colors (verified yes/no, asset id, units)
    # - array of output colors (verified yes/no, asset id, units) - do not contain marker output
    def data
      data = "".b
      txdata = @transaction.data
      data << WireFormat.encode_string(txdata)
      @inputs.each do |ain|
        data << ain.assets_data
      end
      @outputs.each do |aout|
        if !aout.marker?
          data << aout.assets_data
        end
      end
      data
    end

    def metadata
      marker ? marker.metadata : nil
    end

    def transaction_hash
      @transaction.transaction_hash
    end

    def transaction_id
      @transaction.transaction_id
    end

    def issue_outputs
      @outputs.find_all{|o| o.issue? }
    end

    def transfer_outputs
      @outputs.find_all{|o| o.transfer? }
    end

    # AssetTransaction is considered verified when all outputs are verified.
    # Inputs may remain unverified when their assets are destroyed.
    def verified?
      outputs_verified?
    end

    def inputs_verified?
      @inputs.all?{|i|i.verified?}
    end

    def outputs_verified?
      @outputs.all?{|o|o.verified?}
    end

    def output_at_raw_index(i) # deprecated
      @outputs[i]
      # @outputs.find do |out|
      #   raise ArgumentError, "Underlying BTC::TransactionOutput instance are expected to have `index` attribute." if !out.index
      #   out.index == i
      # end
    end

    def dup
      atx = AssetTransaction.new(transaction: self.transaction.dup)
      self.inputs.each_with_index do |ain, i|
        ain2 = atx.inputs[i]
        ain2.asset_id = ain.asset_id
        ain2.value = ain.value
        ain2.verified = ain.verified
      end
      self.outputs.each_with_index do |aout, i|
        aout2 = atx.outputs[i]
        aout2.asset_id = aout.asset_id
        aout2.value = aout.value
        aout2.verified = aout.verified
        aout2.kind = aout.kind
      end
    end

    def inspect
      issues = issue_outputs.map{|out| out.value.inspect }.join(",")
      ins = inputs.map{|inp| inp.value.inspect }.join(",")
      outs = transfer_outputs.map{|out| out.value.inspect }.join(",")
      %{#<#{self.class}:#{self.transaction_id[0,8]} issues [#{issues}] transfers [#{ins}] => [#{outs}]>}
    end

    protected
    attr_writer :transaction
    attr_writer :inputs
    attr_writer :outputs
    attr_writer :marker
  end
end
