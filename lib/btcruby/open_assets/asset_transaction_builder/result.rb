module BTC
  AssetTransactionBuilder
  class AssetTransactionBuilder
    
    # Result object containing transaction itself and various info about it.
    # You get this object from `AssetTransactionBuilder#build` method.
    class Result
      # Array of BTC::Transaction instances.
      # These may have unsigned inputs and must be published in the order.
      # The last transaction is wrapped by the `asset_transaction`.
      # Typically, this array contains just one transaction. When issuing an asset,
      # it may contain two transactions.
      attr_reader :transactions

      # Array of arrays. Each top-level array refers to a list of input indexes to be signed.
      # Some inputs can be signed already.
      attr_reader :unsigned_input_indexes

      # AssetTransaction instance with full details about asset issuance and transfer.
      attr_reader :asset_transaction

      # Total mining fee for all composed transactions.
      attr_reader :fee

      # Total cost of all issues and transfers (not including the mining fees and asset change outputs)
      # All of that amount is owned by the asset holders and can be extracted or returned during re-sell.
      attr_reader :assets_cost
      
      def initialize
        self.transactions = []
        self.unsigned_input_indexes = []
        self.asset_transaction = nil
        self.fee = 0
        self.assets_cost = 0
      end
    end    

    # Internal-only setters.
    class Result
      attr_accessor :transactions
      attr_accessor :unsigned_input_indexes
      attr_accessor :asset_transaction
      attr_accessor :fee
      attr_accessor :assets_cost
    end
  end
end
