module BTC
  # Nodes collect new transactions into a block, hash them into a hash tree,
  # and scan through nonce values to make the block's hash satisfy proof-of-work
  # requirements.  When they solve the proof-of-work, they broadcast the block
  # to everyone and the block is added to the block chain.  The first transaction
  # in the block is a special one that creates a new coin owned by the creator
  # of the block.
  class Block < BlockHeader

    # Array of BTC::Transaction objects
    attr_accessor :transactions

    def self.genesis_mainnet
      self.new(
        version:             1,
        previous_block_hash: ZERO_HASH256,
        merkle_root:         BTC.from_hex("3ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a"),
        timestamp:           1231006505,
        bits:                0x1d00ffff,
        nonce:               0x7c2bac1d,
        transactions:        [BTC::Transaction.new(
          version:   1,
          inputs:    [
            BTC::TransactionInput.new(
              coinbase_data: BTC.from_hex("04FFFF001D010445"+
              "5468652054696D65732030332F4A616E2F32303039204368616E63656C6C6F72206F6E2062" +
              "72696E6B206F66207365636F6E64206261696C6F757420666F722062616E6B73"),
            )
          ],
          outputs:   [
            BTC::TransactionOutput.new(
              value: 50*COIN,
              script: Script.new(data: BTC.from_hex("4104678AFDB0FE5548271967F1"+
              "A67130B7105CD6A828E03909A67962E0EA1F61DEB649F6BC3F4CEF38"+
              "C4F35504E51EC112DE5C384DF7BA0B8D578A4C702B6BF11D5FAC"))
            )
          ],
          lock_time: 0
        )],
        height: 0
      )
    end

    def self.genesis_testnet
      self.new(
        version:             1,
        previous_block_hash: ZERO_HASH256,
        merkle_root:         BTC.from_hex("3ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a"),
        timestamp:           1296688602,
        bits:                0x1d00ffff,
        nonce:               0x18aea41a,
        transactions:        [BTC::Transaction.new(
          version:   1,
          inputs:    [
            BTC::TransactionInput.new(
              coinbase_data: BTC.from_hex("04FFFF001D010445"+
              "5468652054696D65732030332F4A616E2F32303039204368616E63656C6C6F72206F6E2062" +
              "72696E6B206F66207365636F6E64206261696C6F757420666F722062616E6B73"),
            )
          ],
          outputs:   [
            BTC::TransactionOutput.new(
              value: 50*COIN,
              script: Script.new(data: BTC.from_hex("4104678AFDB0FE5548271967F1"+
              "A67130B7105CD6A828E03909A67962E0EA1F61DEB649F6BC3F4CEF38"+
              "C4F35504E51EC112DE5C384DF7BA0B8D578A4C702B6BF11D5FAC"))
            )
          ],
          lock_time: 0
        )],
        height: 0
      )
    end

    def initialize(data: nil,
                   stream: nil,
                   version: CURRENT_VERSION,
                   previous_block_hash: nil,
                   previous_block_id: nil,
                   merkle_root: nil,
                   timestamp: 0,
                   time: nil,
                   bits: 0,
                   nonce: 0,
                   transactions: [],

                   # optional attributes
                   height: nil,
                   confirmations: nil)
      super(
                       data: data,
                     stream: stream,
                    version: version,
        previous_block_hash: previous_block_hash,
          previous_block_id: previous_block_id,
                merkle_root: merkle_root,
                  timestamp: timestamp,
                       time: time,
                       bits: bits,
                      nonce: nonce,
                     height: height,
              confirmations: confirmations
      )

      @transactions = transactions if transactions
    end

    def init_with_stream(stream)
      super(stream)
      if !(txs_count = BTC::WireFormat.read_varint(stream: stream).first)
        raise ArgumentError, "Failed to read count of transactions from the stream."
      end
      txs = (0...txs_count).map do
        Transaction.new(stream: stream)
      end
      @transactions = txs
    end

    def data
      data = super
      data << BTC::WireFormat.encode_varint(self.transactions.size)
      self.transactions.each do |tx|
        data << tx.data
      end
      data
    end

    def block_header
      BlockHeader.new(
        version:             self.version,
        previous_block_hash: self.previous_block_hash,
        merkle_root:         self.merkle_root,
        timestamp:           self.timestamp,
        bits:                self.bits,
        nonce:               self.nonce,
        height:              self.height,
        confirmations:       self.confirmations)
    end

    def ==(other)
      super(other) && @transactions == other.transactions
    end

    def dup
      self.class.new(
        version:             self.version,
        previous_block_hash: self.previous_block_hash,
        merkle_root:         self.merkle_root,
        timestamp:           self.timestamp,
        bits:                self.bits,
        nonce:               self.nonce,
        transactions:        self.transactions.map{|t|t.dup},
        height:              self.height,
        confirmations:       self.confirmations)
    end

    def inspect
      %{#<#{self.class.name}:#{self.block_id[0,24]}} +
      %{ ver:#{self.version}} +
      %{ prev:#{self.previous_block_id[0,24]}} +
      %{ merkle_root:#{BTC.id_from_hash(self.merkle_root)[0,16]}} +
      %{ timestamp:#{self.timestamp}} +
      %{ bits:0x#{self.bits.to_s(16)}} +
      %{ nonce:0x#{self.nonce.to_s(16)}} +
      %{ txs(#{self.transactions.size}): #{self.transactions.inspect}} +
      %{>}
    end

  end
end