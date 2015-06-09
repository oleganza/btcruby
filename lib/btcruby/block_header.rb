module BTC
  # Block header is the 80-byte prefix of the block.
  # Nodes collect new transactions into a block, hash them into a hash tree,
  # and scan through nonce values to make the block's hash satisfy proof-of-work
  # requirements.  When they solve the proof-of-work, they broadcast the block
  # to everyone and the block is added to the block chain.  The first transaction
  # in the block is a special one that creates a new coin owned by the creator
  # of the block.
  class BlockHeader

    CURRENT_VERSION = 2
    ZERO_HASH256  = "\x00".b*32

    # Binary hash of the block
    attr_reader :block_hash

    # Hex big-endian hash of the block
    attr_reader :block_id

    # Block version.
    attr_accessor :version

    # Binary hash of the previous block
    attr_accessor :previous_block_hash

    # Hex big-endian hash of the previous block
    attr_accessor :previous_block_id

    # Raw binary root hash of the transaction merkle tree.
    attr_accessor :merkle_root

    # uint32 unix timestamp
    attr_accessor :timestamp

    # Time object derived from timestamp
    attr_accessor :time

    # uint32 proof-of-work in compact format
    attr_accessor :bits

    # uint32 nonce (used for mining iterations)
    attr_accessor :nonce


    # Optional attributes.
    # These are not derived from block data, but attached externally (e.g. via external APIs).

    # The distance from the first block in the chain (genesis block has height 0).
    attr_accessor :height

    # The number of blocks that have been processed since the previous block (including the block itself).
    attr_accessor :confirmations

    attr_accessor :my_name

    def self.genesis_mainnet
      self.new(
        version:             1,
        previous_block_hash: ZERO_HASH256,
        merkle_root:         BTC.from_hex("3ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a"),
        timestamp:           1231006505,
        bits:                0x1d00ffff,
        nonce:               0x7c2bac1d,
        height:              0
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
        height:              0
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

                   # optional attributes
                   height: nil,
                   confirmations: nil)

      if stream || data
        init_with_stream(stream || StringIO.new(data))
      else
        @version = version || CURRENT_VERSION
        @previous_block_hash = previous_block_hash || ZERO_HASH256
        @previous_block_hash = BTC.hash_from_id(previous_block_id) if previous_block_id
        @merkle_root = merkle_root || ZERO_HASH256
        @timestamp   = timestamp   || 0
        @timestamp   = time.to_i if time
        @bits        = bits        || 0
        @nonce       = nonce       || 0
      end

      @height = height
      @confirmations = confirmations
    end

    def init_with_stream(stream)
      raise ArgumentError, "Stream is missing" if !stream
      if stream.eof?
        raise ArgumentError, "Can't parse block header from stream because it is already closed."
      end

      if !(version = BTC::WireFormat.read_int32le(stream: stream).first)
        raise ArgumentError, "Failed to read block version prefix from the stream."
      end

      if !(prevhash = stream.read(32)) || prevhash.bytesize != 32
        raise ArgumentError, "Failed to read 32-byte previous_block_hash from the stream."
      end

      if !(mrklroot = stream.read(32)) || mrklroot.bytesize != 32
        raise ArgumentError, "Failed to read 32-byte block merkle_root from the stream."
      end

      if !(timestamp = BTC::WireFormat.read_uint32le(stream: stream).first)
        raise ArgumentError, "Failed to read 32-byte block timestamp from the stream."
      end

      if !(bits = BTC::WireFormat.read_uint32le(stream: stream).first)
        raise ArgumentError, "Failed to read 32-byte proof-of-work bits from the stream."
      end

      if !(nonce = BTC::WireFormat.read_uint32le(stream: stream).first)
        raise ArgumentError, "Failed to read 32-byte nonce from the stream."
      end

      @version = version
      @previous_block_hash = prevhash
      @merkle_root = mrklroot
      @timestamp = timestamp
      @bits = bits
      @nonce = nonce
    end

    def block_hash
      BTC.hash256(self.header_data)
    end

    def block_id
      BTC.id_from_hash(self.block_hash)
    end

    def previous_block_id
      BTC.id_from_hash(self.previous_block_hash)
    end

    def previous_block_id=(block_id)
      self.previous_block_hash = BTC.hash_from_id(block_id)
    end

    def time
      Time.at(self.timestamp).utc
    end

    def time=(time)
      self.timestamp = time.to_i
    end

    def data
      header_data
    end

    def header_data # so that in subclass Block we don't hash the entire block
      data = "".b
      data << BTC::WireFormat.encode_int32le(self.version)
      data << self.previous_block_hash
      data << self.merkle_root
      data << BTC::WireFormat.encode_uint32le(self.timestamp)
      data << BTC::WireFormat.encode_uint32le(self.bits)
      data << BTC::WireFormat.encode_uint32le(self.nonce)
      data
    end

    def ==(other)
                  @version == other.version &&
      @previous_block_hash == other.previous_block_hash &&
              @merkle_root == other.merkle_root &&
                @timestamp == other.timestamp &&
                     @bits == other.bits &&
                    @nonce == other.nonce
    end
    alias_method :eql?, :==

    def dup
      self.class.new(
        version:             self.version,
        previous_block_hash: self.previous_block_hash,
        merkle_root:         self.merkle_root,
        timestamp:           self.timestamp,
        bits:                self.bits,
        nonce:               self.nonce,
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
      %{>}
    end

  end
end
