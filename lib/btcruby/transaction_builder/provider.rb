module BTC
  TransactionBuilder
  class TransactionBuilder

    # Interface for providing unspent outputs to transaction builder.
    # You can use it instead of Enumerable attribute `unspent_outputs` to customize which unspents to be used.
    module Provider
      # Returns an Enumerable object yielding unspent outputs for the given addresses.
      # Each unspent output is a BTC::TransactionOutput instance with non-nil `transaction_hash` and `index` attributes.
      # Additional information about outputs and fees may be used to optimize the set of unspents.
      # If builder's `outputs_amount` is nil, all available unspent outputs are expected to be returned.
      def unspent_outputs(transaction_builder)
        []
      end

      # Allows provider to track unspents that are actually used by the transaction builder,
      # so it can avoid providing the same outputs to another transaction builder.
      def consume_unspent_output(output)
        #puts "========> BTCRUBY: Provider #{self.object_id} consumes output #{btc_txbuilder_outpoint_id(output)}."
        @btc_txbuilder_provider_consumed_unspent_outputs ||= {}
        @btc_txbuilder_provider_consumed_unspent_outputs[btc_txbuilder_outpoint_id(output)] = 1
        self
      end

      def consumed_unspent_output?(output)
        #puts "========> BTCRUBY: Does Provider #{self.object_id} have output #{btc_txbuilder_outpoint_id(output)}?"
        !!((@btc_txbuilder_provider_consumed_unspent_outputs ||= {})[btc_txbuilder_outpoint_id(output)])
      end

      def btc_txbuilder_outpoint_id(output)
        raise ArgumentError, "Output must have txid" if !output.transaction_hash
        raise ArgumentError, "Output must have txid" if !output.index
        output.outpoint_id
      end

      # Creates a block-based provider:
      # txbuilder.provider = TransactionBuilder::Provider.new {|builder|  [...]  }
      def self.new(&block)
        BlockProvider.new(&block)
      end

      class BlockProvider # private
        include Provider
        def initialize(&block)
          @block = block
        end
        def unspent_outputs(txbuilder)
          @block.call(txbuilder)
        end
      end
    end

  end
end
