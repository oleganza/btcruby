module BTC
  AssetTransactionBuilder
  class AssetTransactionBuilder
    
    # Interface for providing unspent asset outputs to the asset transaction builder.
    # You can use it instead of Enumerable attribute `asset_unspent_outputs` to customize which unspents to be used.
    module Provider
      # Returns an Enumerable object yielding unspent asset outputs for the given asset ID and amount.
      # Each unspent output is a BTC::AssetTransactionOutput instance with non-nil `transaction_hash`, `index`, `asset_id`, `value` attributes.
      # Additional information about outputs and fees may be used to optimize the set of unspents.
      def asset_unspent_outputs(asset_id: nil, amount: nil)
        []
      end
      
      # Creates a block-based provider:
      # atxbuilder.provider = AssetTransactionBuilder::Provider.new {|builder|  [...]  }
      def self.new(&block)
        BlockProvider.new(&block)
      end
      
      class BlockProvider # private
        include Provider
        def initialize(&block)
          @block = block
        end
        def asset_unspent_outputs(atxbuilder)
          @block.call(atxbuilder)
        end
      end
    end
  end
end
