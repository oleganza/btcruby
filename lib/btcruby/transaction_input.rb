# Transaction input (aka "txin") represents a reference to another transaction's output.
# Reference is defined by tx hash + tx output index.
# Signature script is used to prove ownership of the corresponding tx output.
# Sequence is used to require different signatures when tx is updated. It is only relevant when tx lock_time > 0.
module BTC
  class TransactionInput

    INVALID_INDEX = 0xFFFFFFFF # aka "(unsigned int) -1" in BitcoinQT.
    MAX_SEQUENCE  = 0xFFFFFFFF
    ZERO_HASH256  = "\x00".b*32

    # Hash of the previous transaction (raw binary hash)
    attr_accessor :previous_hash

    # ID of a previous transaction (reversed hash in hex)
    attr_accessor :previous_id

    # Index of the previous transaction's output (uint32_t).
    attr_accessor :previous_index

    # BTC::Script instance that proves ownership of the previous transaction output.
    # We intentionally do not call it "script" to avoid accidental confusion with
    # TransactionOutput#script.
    attr_accessor :signature_script

    # Binary String contained in signature script in coinbase input.
    # Returns nil if it is not a coinbase input.
    attr_accessor :coinbase_data

    # Input sequence (uint32_t). Default is maximum value 0xFFFFFFFF.
    # Sequence is used to update a timelocked tx stored in memory of the nodes. It is only relevant when tx lock_time > 0.
    # Currently, for DoS and security reasons, nodes do not store timelocked transactions making the sequence number meaningless.
    attr_accessor :sequence

    # Binary representation of the input in wire format (aka payload).
    attr_reader :data

    # Dictionary representation of transaction ready to be encoded in JSON, PropertyList etc.
    attr_reader :dictionary

    # Optional reference to the owning transaction.
    # It is set in `tx.add_input` and reset to nil in `tx.remove_all_inputs`.
    # Default is nil.
    attr_accessor :transaction
    
    # Optional index within owning transaction. 
    # It is set in `tx.add_input` and reset to nil in `tx.remove_all_inputs`.
    # Default is nil.
    attr_accessor :index

    # Optional attribute referencing an output that this input is spending.
    attr_accessor :transaction_output

    # Optional attribute containing a value in the corresponding output (in satoshis).
    # Default is transaction_output.value or nil.
    attr_accessor :value

    # Initializes transaction input with its attributes. Every attribute has a valid default value.
    def initialize(data: nil,
                   stream: nil,
                   dictionary: nil,
                   previous_hash: ZERO_HASH256,
                   previous_id: nil,
                   previous_index: INVALID_INDEX,
                   coinbase_data: nil,
                   signature_script: BTC::Script.new,
                   sequence: MAX_SEQUENCE,

                   # optional attributes
                   transaction: nil,
                   transaction_output: nil,
                   value: nil)
      if stream || data
        init_with_stream(stream || StringIO.new(data))
      elsif dictionary
        init_with_dictionary(dictionary)
      else
        @previous_hash    = previous_hash    || ZERO_HASH256
        @previous_hash    = BTC.hash_from_id(previous_id) if previous_id
        @previous_index   = previous_index   || INVALID_INDEX
        @coinbase_data    = coinbase_data
        @signature_script = signature_script || BTC::Script.new
        @sequence         = sequence         || MAX_SEQUENCE
      end

      @transaction = transaction

      @transaction_output = transaction_output
      # Try to set outpoint data based on transaction output.
      if @transaction_output
        if @previous_hash == ZERO_HASH256
          @previous_hash = @transaction_output.transaction_hash || ZERO_HASH256
        end
        if @previous_index == INVALID_INDEX
          @previous_index = @transaction_output.index || INVALID_INDEX
        end
      end
      @value = value
    end

    def init_with_stream(stream)
      if stream.eof?
        raise ArgumentError, "Can't parse transaction input from stream because it is already closed."
      end

      if !(@previous_hash = stream.read(32)) || @previous_hash.bytesize != 32
        raise ArgumentError, "Failed to read 32-byte previous_hash from stream."
      end

      if !(@previous_index = BTC::WireFormat.read_uint32le(stream: stream).first)
        raise ArgumentError, "Failed to read previous_index from stream."
      end

      is_coinbase = (@previous_hash == ZERO_HASH256 && @previous_index == INVALID_INDEX)

      if !(scriptdata = BTC::WireFormat.read_string(stream: stream).first)
        raise ArgumentError, "Failed to read signature_script data from stream."
      end

      @coinbase_data = nil
      @signature_script = nil

      if is_coinbase
        @coinbase_data = scriptdata
      else
        @signature_script = BTC::Script.new(data: scriptdata)
      end

      if !(@sequence = BTC::WireFormat.read_uint32le(stream: stream).first)
        raise ArgumentError, "Failed to read sequence from stream."
      end
    end

    def init_with_dictionary(dict)
      raise ArgumentError, "Dictionary is missing" if !dict

      # Supports bitcoin-QT RPC format

      if dict["prev_out"] && !dict["prev_out"].is_a?(Hash)
        raise ArgumentError, "prev_out is not a dictionary."
      end

      prevhash = ZERO_HASH256
      previndex = INVALID_INDEX
      script = nil
      seq = MAX_SEQUENCE

      if dict["prev_out"]
        if hashhex = dict["prev_out"]["hash"]
          prevhash = BTC.from_hex(hashhex)
          if prevhash.bytesize != 32
            raise ArgumentError, "prev_out.hash is not 32 bytes long."
          end
        end

        if n = dict["prev_out"]["n"]
          index = n.to_i
          if index < 0 || index > 0xffffffff
            raise ArgumentError, "prev_out.n is out of bounds (#{index})."
          end
          previndex = index
        end
      end

      coinbase_data = nil
      script = nil
      if hex = dict["coinbase"]
        coinbase_data = BTC.from_hex(hex)
      elsif dict["scriptSig"]
        if dict["scriptSig"].is_a?(Hash)
          if hex = dict["scriptSig"]["hex"]
            script = BTC::Script.new(data: BTC.from_hex(hex))
          end
        end
      end

      if dict["sequence"]
        seq = dict["sequence"].to_i
        if seq < 0 || seq > MAX_SEQUENCE
          raise ArgumentError, "sequence is out of bounds (#{index})."
        end
      end

      @previous_hash = prevhash
      @previous_index = previndex,
      @coinbase_data = coinbase_data
      @signature_script = script
      @sequence = seq
    end

    # Returns true if this input is a coinbase input.
    def coinbase?
      return self.previous_index == INVALID_INDEX && self.previous_hash == ZERO_HASH256
    end

    def previous_id
      BTC.id_from_hash(self.previous_hash)
    end

    def previous_id=(txid)
      self.previous_hash = BTC.hash_from_id(txid)
    end

    def value
      return @value if @value
      return @transaction_output.value if @transaction_output
      return nil
    end

    def data
      data = "".b
      data << BTC::Data.ensure_binary_encoding(self.previous_hash)
      data << BTC::WireFormat.encode_uint32le(self.previous_index)
      if coinbase?
        data << BTC::WireFormat.encode_string(self.coinbase_data)
      else
        data << BTC::WireFormat.encode_string(self.signature_script.data)
      end
      data << BTC::WireFormat.encode_uint32le(self.sequence)
      data
    end

    def dictionary
      dict = {}

      dict["prev_out"] = {
        "hash" => BTC.to_hex(self.previous_hash),
        "n"    => self.previous_index
      }

      if self.coinbase?
        dict["coinbase"] = BTC.to_hex(self.coinbase_data)
      else
        dict["scriptSig"] = {
          "asm" => self.signature_script.to_s,
          "hex" => BTC.to_hex(self.signature_script.data)
        }
      end

      dict["sequence"] = self.sequence

      dict
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

    # Makes a deep copy of a transaction input
    def dup
      TransactionInput.new(previous_hash: @previous_hash.dup,
                          previous_index: @previous_index,
                        signature_script: @signature_script ? @signature_script.dup : nil,
                           coinbase_data: @coinbase_data,
                                sequence: @sequence,
                             transaction: @transaction,
                      transaction_output: @transaction_output, # not dup-ing txout because it's a transient object without #==
                                   value: @value)
    end

    def inspect(style = :full)
      if style == :full
        %{#<#{self.class.name} prev:#{self.previous_id}[#{self.previous_index}]} +
        %{ script:#{self.signature_script.to_s.inspect}} +
        %{ seq:#{self.sequence}} +
        %{>}
      else
        %{#<#{self.class.name} prev:#{self.previous_id[0,10]}[#{self.previous_index}]} +
        %{ script:#{self.signature_script.to_s.inspect}} +
        (self.sequence != MAX_SEQUENCE ? %{ seq:#{self.sequence}} : %{}) +
        %{>}
      end
    end

  end
end
