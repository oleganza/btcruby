# Transaction output (aka "tx out") is a value with rules attached in form of a script.
# To spend money one need to choose a transaction output and provide an appropriate
# input which makes the script execute with success.
module BTC
  class TransactionOutput

    # Core attributes.

    # Value of output in satoshis.
    attr_accessor :value

    # BTC::Script defining redemption rules for this output (aka scriptPubKey or pk_script)
    attr_accessor :script


    # Derived attributes.

    # Serialized binary form of the output (payload)
    attr_reader :data

    # Dictionary representation of transaction ready to be encoded in JSON, PropertyList etc.
    attr_reader :dictionary


    # Optional attributes.

    # These are not derived from tx data, but attached externally (e.g. via external APIs).
    # 'index', 'confirmations' and 'transaction_hash' are optional attributes updated in certain context.
    # E.g. when loading unspent outputs from Chain.com, all these attributes will be set.
    # index and transaction_hash are kept up to date when output is added/removed from the transaction.

    # Reference to the owning transaction. It is set on tx.add_output() and
    # reset to nil on tx.remove_all_outputs. Default is nil.
    attr_accessor :transaction

    # Identifier of the transaction. Default is nil.
    attr_accessor :transaction_hash

    # Transaction ID. Always in sync with transaction_hash. Default is nil.
    attr_accessor :transaction_id

    # Index of this output in its transaction. Default is nil (unknown).
    attr_accessor :index

    # Binary hash of the block at which transaction was included.
    # If not confirmed or not available, equals nil.
    attr_accessor :block_hash
    attr_accessor :block_id

    # Height of the block at which transaction was included.
    # If not confirmed equals -1.
    # Note: `block_height` might not be provided by some APIs while `confirmations` may be.
    # Default value is derived from `transaction` if possible or equals nil.
    attr_accessor :block_height

    # Time of the block at which tx was included (::Time instance or nil).
    # Default value is derived from `transaction` if possible or equals nil.
    attr_accessor :block_time

    # Number of confirmations.
    # Default value is derived from `transaction` if possible or equals nil.
    attr_accessor :confirmations

    # If available, returns whether this output is spent (true or false).
    # Default is nil.
    # See also `spent_confirmations`.
    attr_accessor :spent

    # If this transaction is spent, contains number of confirmations of the spending transaction.
    # Returns nil if not available or output is not spent.
    # Returns 0 if spending transaction is unconfirmed.
    attr_accessor :spent_confirmations

    def initialize(data: nil,
                   stream: nil,
                   dictionary: nil,
                   value: 0,
                   script: BTC::Script.new,

                   # optional attributes
                   transaction: nil,
                   transaction_hash: nil,
                   transaction_id: nil,
                   index: nil,
                   block_hash: nil,
                   block_id: nil,
                   block_height: nil,
                   block_time: nil,
                   confirmations: nil,
                   spent: nil,
                   spent_confirmations: nil)

      if stream || data
        init_with_stream(stream || StringIO.new(data))
      elsif dictionary
        init_with_dictionary(dictionary)
      else
        @value = value || 0
        @script = script || BTC::Script.new
      end

      @transaction = transaction
      @transaction_hash = transaction_hash
      @transaction_hash = BTC.hash_from_id(transaction_id) if transaction_id
      @index = index
      @block_hash = block_hash
      @block_hash = BTC.hash_from_id(block_id) if block_id
      @block_height = block_height
      @block_time = block_time
      @confirmations = confirmations
      @spent = spent
      @spent_confirmations = spent_confirmations
    end

    def init_with_stream(stream)
      if stream.eof?
        raise ArgumentError, "Can't parse transaction output from stream because it is already closed."
      end

      # Read value
      if !(@value = BTC::WireFormat.read_int64le(stream: stream).first)
        raise ArgumentError, "Failed to read output value from stream."
      end

      # Read script
      if !(scriptdata = BTC::WireFormat.read_string(stream: stream).first)
        raise ArgumentError, "Failed to read output script data from stream."
      end

      @script = BTC::Script.new(data: scriptdata)
    end

    def init_with_dictionary(dict)
      @value = 0
      if amount_string = dict["value"]
        @value = CurrencyFormatter.btc_long_formatter.number_from_string(amount_string)
        if !@value
          raise ArgumentError, "Failed to parse bitcoin amount from dictionary 'value': #{amount_string.inspect}"
        end
      end

      @script = nil
      if dict["scriptPubKey"] && dict["scriptPubKey"].is_a?(Hash)
        if hex = dict["scriptPubKey"]["hex"]
          @script = Script.new(data: BTC.from_hex(hex))
          if !@script
            raise ArgumentError, "Failed to parse script from scriptPubKey.hex"
          end
        end
      end
    end

    def data
      data = "".b
      data << BTC::WireFormat.encode_int64le(self.value)
      data << BTC::WireFormat.encode_string(self.script.data)
      data
    end

    def dictionary
      {
        "value" => CurrencyFormatter.btc_long_formatter.string_from_number(self.value),
        "scriptPubKey" => {
          "asm" => self.script.to_s,
          "hex" => BTC.to_hex(self.script.data)
        }
      }
    end

    def transaction=(tx)
      @transaction = tx
      @transaction_hash = nil
      @outpoint = nil
    end

    def index=(i)
      @index = i
      @outpoint = nil
    end

    def transaction_hash
      return @transaction_hash             if @transaction_hash
      return @transaction.transaction_hash if @transaction
      return nil
    end

    def transaction_hash=(txhash)
      @transaction_hash = txhash
      @outpoint = nil
    end

    def transaction_id=(txid)
      self.transaction_hash = BTC.hash_from_id(txid)
    end

    def transaction_id
      BTC.id_from_hash(self.transaction_hash)
    end

    def outpoint
      return @outpoint if @outpoint
      if transaction_hash && index
        @outpoint = TransactionOutpoint.new(transaction_hash: transaction_hash, index: index)
      end
      @outpoint
    end

    def outpoint_id
      outpoint.outpoint_id
    end

    def block_id
      BTC.id_from_hash(self.block_hash)
    end

    def block_id=(block_id)
      self.block_hash = BTC.hash_from_id(block_id)
    end

    def block_hash
      return @block_hash if @block_hash
      return @transaction.block_hash if @transaction
      return nil
    end

    def block_height
      return @block_height if @block_height
      return @transaction.block_height if @transaction
      return nil
    end

    def block_time
      return @block_time if @block_time
      return @transaction.block_time if @transaction
      return nil
    end

    def confirmations
      return @confirmations if @confirmations
      return @transaction.confirmations if @transaction
      return nil
    end

    # Returns `true` if this transaction output contains an Open Assets marker.
    # Does not perform expensive validation.
    # Use this method to quickly filter out non-asset transactions.
    def open_assets_marker?
      self.script.open_assets_marker?
    end

    def dust?(relay_fee_rate = Transaction::DEFAULT_RELAY_FEE_RATE)
      return self.value < self.dust_limit(relay_fee_rate)
    end

    def dust_limit(relay_fee_rate = Transaction::DEFAULT_RELAY_FEE_RATE)
      # "Dust" is defined in terms of Transaction::DEFAULT_RELAY_FEE_RATE,
      # which has units satoshis-per-kilobyte.
      # If you'd pay more than 1/3 in fees
      # to spend something, then we consider it dust.
      # A typical txout is 34 bytes big, and will
      # need a TransactionInput of at least 148 bytes to spend:
      # so dust is a txout less than 546 satoshis (3*(34+148))
      # with default relay_fee_rate.
      size = self.data.bytesize + 148
      return 3*Transaction.compute_fee(size, fee_rate: relay_fee_rate)
    end

    def to_h
      self.dictionary
    end

    def to_s
      BTC.to_hex(self.data)
    end

    def ==(other)
      return true if super(other)
      return true if self.data == other.data
      return false
    end

    # Makes a deep copy of a transaction output
    def dup
      TransactionOutput.new(value: @value,
                            script: @script.dup,
                            transaction: @transaction,
                            transaction_hash: @transaction_hash,
                            index: @index,
                            block_hash: @block_hash,
                            block_height: @block_height,
                            block_time: @block_time,
                            confirmations: @confirmations,
                            spent: @spent,
                            spent_confirmations: @spent_confirmations)
    end

    def inspect(style = :full)
      %{#<#{self.class.name} value:#{CurrencyFormatter.btc_long_formatter.string_from_number(self.value)}} +
      %{ script:#{self.script.to_s.inspect}>}
    end

  end
end
