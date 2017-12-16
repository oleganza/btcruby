module BTC
  class SegwitTransaction < Transaction
    def witness
      inputs.reduce(''.b) do |serialized, txin|
        serialized << BTC::WireFormat.encode_array(txin.witness) { |data| BTC::WireFormat.encode_string(data) }
      end
    end

    def data
      data = "".b
      data << BTC::WireFormat.encode_int32le(self.version)
      data << BTC::WireFormat.encode_uint8(0x00) # marker
      data << BTC::WireFormat.encode_uint8(0x01) # flag
      data << BTC::WireFormat.encode_varint(self.inputs.size)
      self.inputs.each do |txin|
        data << txin.data
      end
      data << BTC::WireFormat.encode_varint(self.outputs.size)
      self.outputs.each do |txout|
        data << txout.data
      end
      data << self.witness
      data << BTC::WireFormat.encode_uint32le(lock_time)
      data
    end

    # Calculate version 0 witness compatible digest as defined in BIP-143
    def signature_hash(input_index: nil, output_script: nil, hash_type: BTC::SIGHASH_ALL, amount: 0)
      raise ArgumentError, "Should specify input_index in Transaction#signature_hash." if !input_index
      raise ArgumentError, "Should specify output_script in Transaction#signature_hash." if !output_script
      raise ArgumentError, "Should specify hash_type in Transaction#signature_hash." if !hash_type

      hash_prevouts = 0
      hash_sequence = 0
      hash_outputs = 0
      tx = self.dup

      if (hash_type & BTC::SIGHASH_ANYONECANPAY) == 0
        serialized_prevouts = ''.b
        tx.inputs.each do |txin|
          serialized_prevouts << txin.outpoint.data
        end
        hash_prevouts = BTC.sha256(BTC.sha256(serialized_prevouts))
      end

      if (hash_type & BTC::SIGHASH_ANYONECANPAY) == 0 && (hash_type & SIGHASH_OUTPUT_MASK) != BTC::SIGHASH_SINGLE && (hash_type & SIGHASH_OUTPUT_MASK) != BTC::SIGHASH_NONE
        serialized_sequence = ''.b
        tx.inputs.each do |txin|
          serialized_sequence << BTC::WireFormat.encode_uint32le(txin.sequence)
        end
        hash_sequence = BTC.sha256(BTC.sha256(serialized_sequence))
      end

      serialized_outputs = ''.b
      if (hash_type & SIGHASH_OUTPUT_MASK) != BTC::SIGHASH_SINGLE && (hash_type & SIGHASH_OUTPUT_MASK) != BTC::SIGHASH_NONE
        tx.outputs.each do |txout|
          serialized_outputs << txout.data
        end
      elsif (hash_type & SIGHASH_OUTPUT_MASK) == BTC::SIGHASH_SINGLE && input_index < tx.outputs.size
        serialized_outputs = tx.outputs[input_index].data
      end
      hash_outputs = BTC.sha256(BTC.sha256(serialized_outputs))

      hash = ''.b
      hash << BTC::WireFormat.encode_int32le(version)
      hash << hash_prevouts
      hash << hash_sequence
      hash << tx.inputs[input_index].outpoint.data
      hash << BTC::WireFormat.encode_string(output_script.data)
      hash << BTC::WireFormat.encode_int64le(amount)
      hash << BTC::WireFormat.encode_uint32le(tx.inputs[input_index].sequence)
      hash << hash_outputs
      hash << BTC::WireFormat.encode_int32le(tx.lock_time)
      hash << BTC::WireFormat.encode_uint32le(hash_type)

      BTC.sha256(BTC.sha256(hash))
    end
  end
end
