module BTC
  # Represents a reference to a previous transaction.
  class Outpoint
    INVALID_INDEX = 0xFFFFFFFF # aka "(unsigned int) -1" in BitcoinQT.
    ZERO_HASH256  = ("\x00".b*32).freeze
    
    attr_accessor :transaction_hash
    attr_accessor :transaction_id
    attr_accessor :index
    
    def initialize(transaction_hash: nil, transaction_id: nil, index: 0)
      @transaction_hash = transaction_hash
      self.transaction_id = transaction_id if transaction_id
      while index < 0
        index += 2**32
      end
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
    
    def null?
      @index == INVALID_INDEX && @transaction_hash == ZERO_HASH256
    end

    def data
      data = "".b
      data << BTC::Data.ensure_binary_encoding(transaction_hash)
      data << BTC::WireFormat.encode_uint32le(index)
      data
    end

    def ==(other)
      index == other.index &&
      transaction_hash == other.transaction_hash
    end
    alias_method :eql?, :==

    def hash
      transaction_hash.hash ^ index
    end

    def to_s
      outpoint_id
    end
  end
  
  # For backwards compatibility keep the longer name.
  TransactionOutpoint = Outpoint
end
