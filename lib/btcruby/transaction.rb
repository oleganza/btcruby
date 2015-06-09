# Transaction represents a bitcoin transfer from one or more inputs to one or more outputs.
require 'stringio'
module BTC

  class Transaction

    CURRENT_VERSION = 1

    DEFAULT_FEE_RATE = 10_000 # satoshis per 1000 bytes
    DEFAULT_RELAY_FEE_RATE = 1000 # satoshis per 1000 bytes

    # Core attributes.

    # Version of the transaction. Default is CURRENT_VERSION.
    attr_accessor :version

    # List of TransactionInputs. See also #add_input and #remove_all_inputs.
    attr_accessor :inputs

    # List of TransactionOutputs. See also #add_output and #remove_all_outputs.
    attr_accessor :outputs

    # Lock time. Either a block height or a unix timestamp.
    # Default is 0.
    attr_accessor :lock_time


    # Derived attributes.

    # 32-byte transaction hash
    attr_reader :transaction_hash

    # Hexadecimal transaction ID with bytes reversed.
    # Used by Chain.com, Blockchain.info, Blockr.io.
    attr_reader :transaction_id

    # Binary representation of the transaction in wire format (aka payload).
    attr_reader :data

    # Dictionary representation of transaction ready to be encoded in JSON, PropertyList etc.
    attr_reader :dictionary


    # Optional Attributes.
    # These are not derived from tx data, but attached externally (e.g. via external APIs).

    # Binary hash of the block at which transaction was included.
    # If not confirmed or not available, equals nil.
    attr_accessor :block_hash

    # Hex-encoded block ID.
    # If not confirmed or not available, equals nil.
    attr_accessor :block_id

    # Height of the block at which transaction was included.
    # If not confirmed equals -1.
    # Note: `block_height` might not be provided by some APIs while `confirmations` may be.
    attr_accessor :block_height

    # Time of the block at which tx was included (::Time instance or nil).
    attr_accessor :block_time

    # Number of confirmations for this transaction (depth in the blockchan).
    # 0 stands for unconfirmed mempool transaction. Default is nil ("no info").
    attr_accessor :confirmations

    # If available, returns mining fee paid by this transaction.
    # If set, `inputs_amount` is updated as (`outputs_amount` + `fee`).
    # Default is nil.
    attr_accessor :fee

    # If available, returns total amount of all inputs.
    # If set, `fee` is updated as (`inputs_amount` - `outputs_amount`).
    # Default is nil.
    attr_accessor :inputs_amount

    # Total amount on all outputs (not including fees).
    # Always available since outputs contain their amounts.
    attr_reader :outputs_amount

    # Initializes transaction with its attributes. Every attribute has a valid default value.
    def initialize(hex: nil,
                   data: nil,
                   stream: nil,
                   dictionary: nil,
                   version: CURRENT_VERSION,
                   inputs: [],
                   outputs: [],
                   lock_time: 0,

                   # optional attributes
                   block_hash: nil,
                   block_id: nil,
                   block_height: nil,
                   block_time: nil,
                   confirmations: nil,
                   fee: nil,
                   inputs_amount: nil)

      data = BTC.from_hex(hex) if hex
      stream = StringIO.new(data) if data
      if stream
        init_with_stream(stream)
      elsif dictionary
        init_with_dictionary(dictionary)
      else
        init_with_components(version: version, inputs: inputs, outputs: outputs, lock_time: lock_time)
      end

      @block_hash = block_hash
      @block_hash = BTC.hash_from_id(block_id) if block_id
      @block_height = block_height
      @block_time = block_time
      @confirmations = confirmations
      @fee = fee
      @inputs_amount = inputs_amount
    end

    def init_with_components(version: CURRENT_VERSION,  inputs: [],  outputs: [], lock_time: 0)
      @version   = version   || CURRENT_VERSION
      @inputs    = inputs    || []
      @outputs   = outputs   || []
      @lock_time = lock_time || 0
      @inputs.each_with_index do |txin, i|
        txin.transaction = self
        txin.index = i
      end
      @outputs.each_with_index do |txout, i|
        txout.transaction = self
        txout.index = i
      end
    end

    def init_with_stream(stream)
      raise ArgumentError, "Stream is missing" if !stream
      if stream.eof?
        raise ArgumentError, "Can't parse transaction from stream because it is already closed."
      end

      if !(version = BTC::WireFormat.read_int32le(stream: stream).first)
        raise ArgumentError, "Failed to read version prefix from the stream."
      end

      if !(inputs_count = BTC::WireFormat.read_varint(stream: stream).first)
        raise ArgumentError, "Failed to read inputs count from the stream."
      end

      txins = (0...inputs_count).map do
        TransactionInput.new(stream: stream)
      end

      if !(outputs_count = BTC::WireFormat.read_varint(stream: stream).first)
        raise ArgumentError, "Failed to read outputs count from the stream."
      end

      txouts = (0...outputs_count).map do
        TransactionOutput.new(stream: stream)
      end

      if !(lock_time = BTC::WireFormat.read_uint32le(stream: stream).first)
        raise ArgumentError, "Failed to read lock_time from the stream."
      end

      init_with_components(version: version, inputs: txins, outputs: txouts, lock_time: lock_time)
    end

    def init_with_dictionary(dict)
      version = dict["ver"] || CURRENT_VERSION
      lock_time = dict["lock_time"] || 0

      txins  = dict["in"].map { |i| TransactionInput.new(dictionary: i) }
      txouts = dict["out"].map {|o| TransactionOutput.new(dictionary: o) }

      init_with_components(version: version, inputs: txins, outputs: txouts, lock_time: lock_time)
    end

    # Returns true if this transaction is a coinbase transaction.
    def coinbase?
      self.inputs.size == 1 && self.inputs[0].coinbase?
    end
    
    # Returns `true` if this transaction contains an Open Assets marker.
    # Does not perform expensive validation.
    # Use this method to quickly filter out non-asset transactions.
    def open_assets_transaction?
      self.outputs.any? {|txout| txout.script.open_assets_marker? }
    end

    def inputs=(inputs)
      remove_all_inputs
      @inputs = inputs || []
      @inputs.each_with_index do |txin, i|
        txin.transaction = self
        txin.index = i
      end
    end

    def outputs=(outputs)
      remove_all_outputs
      @outputs = outputs || []
      @outputs.each_with_index do |txout, i|
        txout.transaction = self
        txout.index = i
      end
    end

    # Adds another input to the transaction.
    def add_input(txin)
      raise ArgumentError, "Input is missing" if !txin
      if !(txin.transaction == nil || txin.transaction == self)
        raise ArgumentError, "Can't add an input to a transaction when it references another transaction" # sanity check
      end
      txin.transaction = self
      txin.index = @inputs.size
      @inputs << txin
      self
    end

    def add_output(txout)
      raise ArgumentError, "Output is missing" if !txout
      if !(txout.transaction == nil || txout.transaction == self)
        raise ArgumentError, "Can't add an output to a transaction when it references another transaction" # sanity check
      end
      txout.transaction = self
      txout.index = @outputs.size
      @outputs << txout
      self
    end

    def remove_all_inputs
      return if !@inputs
      @inputs.each do |txin|
        txin.transaction = nil
        txin.index = nil
      end
      @inputs = []
      self
    end

    def remove_all_outputs
      return if !@outputs
      @outputs.each do |txout|
        txout.transaction = nil
        txout.index = nil
      end
      @outputs = []
      self
    end

    def transaction_hash
      BTC.hash256(self.data)
    end

    def transaction_id
      BTC.id_from_hash(self.transaction_hash)
    end

    def block_id
      BTC.id_from_hash(self.block_hash)
    end

    def block_id=(block_id)
      self.block_hash = BTC.hash_from_id(block_id)
    end

    # Amounts and fee

    def fee=(fee)
      @fee = fee
      @inputs_amount = nil # will be computed from fee.
    end

    def fee
      return @fee if @fee
      if ia = self.inputs_amount
        return (ia - self.outputs_amount)
      end
      return nil
    end

    def inputs_amount=(inputs_amount)
      @inputs_amount = inputs_amount
      @fee = nil # will be computed from inputs_amount. inputs_amount ? (inputs_amount - self.outputs_amount) : nil
    end

    def inputs_amount
      return @inputs_amount if @inputs_amount
      return (@fee + self.outputs_amount) if @fee
      # Try to figure the total amount from amounts on inputs.
      # If all of them are non-nil, we have a valid amount.
      inputs.inject(0) do |total, input|
        if total && (v = input.value)
          total + input.value
        else
          return nil # quickly return nil
        end
      end
    end

    def outputs_amount
      self.outputs.inject(0){|t,o| t + o.value}
    end

    def data
      data = "".b
      data << BTC::WireFormat.encode_int32le(self.version)
      data << BTC::WireFormat.encode_varint(self.inputs.size)
      self.inputs.each do |txin|
        data << txin.data
      end
      data << BTC::WireFormat.encode_varint(self.outputs.size)
      self.outputs.each do |txout|
        data << txout.data
      end
      data << BTC::WireFormat.encode_uint32le(self.lock_time)
      data
    end

    def dictionary
      {
        "hash"      => self.transaction_id,
        "ver"       => self.version,
        "vin_sz"    => self.inputs.size,
        "vout_sz"   => self.outputs.size,
        "lock_time" => self.lock_time,
        "size"      => self.data.bytesize,
        "in"        => self.inputs.map{|i| i.dictionary},
        "out"       => self.outputs.map{|o| o.dictionary}
      }
    end

    # Hash for signing a transaction.
    # You should specify an input index, output script of the previous transaction for that input,
    # and an optional hash type (default is SIGHASH_ALL).
    def signature_hash(input_index: nil, output_script: nil, hash_type: BTC::SIGHASH_ALL)

      raise ArgumentError, "Should specify input_index in Transaction#signature_hash." if !input_index
      raise ArgumentError, "Should specify output_script in Transaction#signature_hash." if !output_script
      raise ArgumentError, "Should specify hash_type in Transaction#signature_hash." if !hash_type

      # Create a temporary copy of the transaction to apply modifications to it.
      tx = self.dup

      # Note: BitcoinQT returns a 256-bit little-endian number 1 in such case,
      # but it does not matter because it would crash before that in CScriptCheck::operator()().
      # We normally won't enter this condition if script machine is instantiated
      # with transaction and input index, but it's better to check anyway.
      if (input_index >= tx.inputs.size)
        raise ArgumentError, "Input index is out of bounds for transaction: #{input_index} >= #{tx.inputs.size}"
      end

      # In case concatenating two scripts ends up with two codeseparators,
      # or an extra one at the end, this prevents all those possible incompatibilities.
      # Note: this normally never happens because there is no use for OP_CODESEPARATOR.
      # But we have to do that cleanup anyway to not break on rare transaction that use that for lulz.
      # Also: we modify the same subscript which is used several times for multisig check,
      # but that's what BitcoinQT does as well.
      output_script.delete_opcode(BTC::OP_CODESEPARATOR)

      # Blank out other inputs' signature scripts
      # and replace our input script with a subscript (which is typically a full
      # output script from the previous transaction).
      tx.inputs.each do |txin|
        txin.signature_script = BTC::Script.new
      end
      tx.inputs[input_index].signature_script = output_script

      # Blank out some of the outputs depending on BTCSignatureHashType
      # Default is SIGHASH_ALL - all inputs and outputs are signed.
      if (hash_type & BTC::SIGHASH_OUTPUT_MASK) == BTC::SIGHASH_NONE
        # Wildcard payee - we can pay anywhere.
        tx.remove_all_outputs

        # Blank out others' input sequence numbers to let others update transaction at will.
        tx.inputs.each_with_index do |txin, i|
          if i != input_index
            tx.inputs[i].sequence = 0
          end
        end

      # Single mode assumes we sign an output at the same index as an input.
      # Outputs before the one we need are blanked out. All outputs after are simply removed.
      elsif (hash_type & BTC::SIGHASH_OUTPUT_MASK) == BTC::SIGHASH_SINGLE

        # Only lock-in the txout payee at same index as txin.
        output_index = input_index;

        # If output_index is out of bounds, BitcoinQT is returning a 256-bit little-endian 0x01 instead of failing with error.
        # We should do the same to stay compatible.
        if output_index >= tx.outputs.size
          return "\x01" + "\x00"*31
        end

        # All outputs before the one we need are blanked out. All outputs after are simply removed.
        # This is equivalent to replacing outputs with (i-1) empty outputs and a i-th original one.
        my_output = tx.outputs[output_index]
        tx.remove_all_outputs
        (0...output_index).each do |i|
          tx.add_output(BTC::TransactionOutput.new)
        end
        tx.add_output(my_output)

        # Blank out others' input sequence numbers to let others update transaction at will.
        tx.inputs.each_with_index do |txin, i|
          if i != input_index
            tx.inputs[i].sequence = 0
          end
        end
      end # if hashtype is none or single

      # Blank out other inputs completely. This is not recommended for open transactions.
      if (hash_type & BTC::SIGHASH_ANYONECANPAY) != 0
        input = tx.inputs[input_index]
        tx.remove_all_outputs
        tx.add_input(input)
      end

      # Important: we have to hash transaction together with its hash type.
      # Hash type is appended as a little endian uint32 unlike 1-byte suffix of the signature.
      data = tx.data + BTC::WireFormat.encode_uint32le(hash_type)
      hash = BTC.hash256(data)

      return hash
    end

    # Compute a fee for a transaction of a given size with a specified per-KB fee rate.
    # By default uses built-in DEFAULT_FEE_RATE.
    # Makes sure that whole number of fee_rate amounts are paid.
    def self.compute_fee(size, fee_rate: DEFAULT_FEE_RATE)
      return 0 if fee_rate <= 0
      fee = fee_rate*size/1000 # according to Bitcoin Core as of March 15, 2015.
      fee = fee_rate if fee == 0
      fee
    end

    # Compute a fee for this transaction with a specified per-KB fee rate.
    # By default uses built-in DEFAULT_FEE_RATE.
    def compute_fee(fee_rate: DEFAULT_FEE_RATE)
      self.class.compute_fee(self.data.bytesize, fee_rate: fee_rate)
    end

    # Returns dictionary representation of the transaction.
    def to_h
      self.dictionary
    end

    # Returns hex representation of the transaction.
    def to_s
      to_hex
    end

    # Returns hex representation of the transaction.
    def to_hex
      BTC.to_hex(self.data)
    end

    # Makes a deep copy of a transaction (all inputs and outputs are copied too).
    def dup
      Transaction.new(version: @version,
                       inputs: (@inputs || []).map{|txin|txin.dup},
                      outputs: (@outputs || []).map{|txout|txout.dup},
                    lock_time: @lock_time,
                   block_hash: @block_hash,
                 block_height: @block_height,
                   block_time: @block_time,
                confirmations: @confirmations,
                          fee: @fee,
                inputs_amount: @inputs_amount)
    end

    def ==(other)
      return false if other == nil
      self.data == other.data
    end
    alias_method :eql?, :==

    def inspect
      %{#<#{self.class.name}:#{transaction_id}} +
      %{ v#{version}} +
      (lock_time > 0 ? %{ lock_time:#{lock_time} #{lock_time > LOCKTIME_THRESHOLD ? 'sec' : 'block'}} : "") +
      %{ inputs:[#{inputs.map{|i|i.inspect(:light)}.join(", ")}]} +
      %{ outputs:[#{outputs.map{|o|o.inspect(:light)}.join(", ")}]} +
      %{>}
    end

  end
end

# if $0 == __FILE__
#   require_relative "../btcruby.rb"
#   require 'pp'
#   include BTC
#
#   tx = Transaction.new
#   puts tx.inspect
#   pp tx.to_h
#   puts tx.to_s
#
# end
