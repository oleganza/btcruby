module BTC
  # Represents a reference to a previous transaction.
  class TransactionOutpoint
    attr_accessor :transaction_hash
    attr_accessor :transaction_id
    attr_accessor :index
    
    def initialize(transaction_hash: nil, transaction_id: nil, index: 0)
      @transaction_hash = transaction_hash
      self.transaction_id = transaction_id if transaction_id
      @index = index
    end
    
    def transaction_id=(txid)
      self.transaction_hash = BTC.hash_from_id(txid)
    end

    def transaction_id
      BTC.id_from_hash(self.transaction_hash)
    end
    
    def outpoint_id
      %{#{transaction_id}:#{index}}
    end
    
    def to_s
      outpoint_id
    end
  end
end
