require_relative 'spec_helper'
describe BTC::TransactionBuilder do

  class SignerByKey
    include TransactionBuilder::Signer
    def initialize(&block)
      @block = block
    end
    def signing_key_for_output(output: nil, address: nil)
      @block.call(output, address)
    end
  end

  class SignerBySignatureScript
    include TransactionBuilder::Signer
    def initialize(&block)
      @block = block
    end
    def signature_script_for_input(input: nil, output: nil)
      @block.call(input, output)
    end
  end

  describe "TransactionBuilder with no outputs" do
    before do
      @builder = TransactionBuilder.new
      @all_utxos = self.mock_utxos

      @builder.input_addresses = self.mock_addresses
      @builder.provider = TransactionBuilder::Provider.new do |txb|
        addrs = txb.public_addresses
        addrs.must_equal self.mock_addresses
        scripts = addrs.map{|a| a.script }.uniq
        @all_utxos.find_all{|utxo| scripts.include?(utxo.script) }
      end
      @builder.change_address = Address.parse("1CBtcGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG")
    end

    it "should fill unspent_outputs using Provider" do
      @builder.unspent_outputs.must_equal @all_utxos
    end

    it "should have a default fee rate" do
      @builder.fee_rate.must_equal Transaction::DEFAULT_FEE_RATE
    end

    it "should return a result" do
      result = @builder.build
      result.class.must_equal TransactionBuilder::Result
    end

    it "should compose a fully-spending transaction when no outputs are given" do
      result = @builder.build
      tx = result.transaction
      tx.inputs.size.must_equal mock_utxos.size
      tx.outputs.size.must_equal 1 # only one change address
    end

    it "should have a list of unsigned indexes" do
      result = @builder.build
      result.unsigned_input_indexes.must_equal (0...(mock_utxos.size)).to_a
    end

    it "should have a reasonable fee" do
      result = @builder.build
      size = result.transaction.data.bytesize # size of unsigned transaction
      result.fee.must_be :>=, (size / 1000)*Transaction::DEFAULT_FEE_RATE
      result.fee.must_be :<, 0.01 * BTC::COIN
    end

    it "should have valid amounts" do
      result = @builder.build
      result.inputs_amount.must_equal mock_utxos.inject(0){|sum, out| sum + out.value}
      result.outputs_amount.must_be :<=, result.inputs_amount
      # Balance should be correct
      result.inputs_amount.must_equal (result.outputs_amount + result.fee)
      result.transaction.inputs.each do |txin|
        # Unsigned txins contain respective output scripts.
        # Signed txins contain data-only signature script (for P2PKH it is signature + pubkey)
        txin.signature_script.data_only?.must_equal false
        txin.signature_script.p2pkh?.must_equal true
      end
    end

    it "should sign if WIFs are provided" do
      @builder.input_addresses = mock_wifs
      result = @builder.build
      result.unsigned_input_indexes.must_equal []
      result.transaction.inputs.each do |txin|
        # Unsigned txins contain respective output scripts.
        # Signed txins contain data-only signature script (for P2PKH it is signature + pubkey)
        txin.signature_script.data_only?.must_equal true
        txin.signature_script.p2pkh?.must_equal false
      end
    end

    it "should sign if signer provides a key" do
      @builder.signer = SignerByKey.new do |txout, addr|
        wif = mock_wifs.find{|wif| wif.public_address == addr}
        wif.key
      end
      result = @builder.build
      result.unsigned_input_indexes.must_equal []
      result.transaction.inputs.each do |txin|
        # Unsigned txins contain respective output scripts.
        # Signed txins contain data-only signature script (for P2PKH it is signature + pubkey)
        txin.signature_script.data_only?.must_equal true
        txin.signature_script.p2pkh?.must_equal false
      end
    end

    it "should sign if signer provides a signature script" do
      @builder.signer = SignerBySignatureScript.new do |txin, txout|
        Script.new << "signature" << "pubkey"
      end
      result = @builder.build
      result.unsigned_input_indexes.must_equal []
      result.transaction.inputs.each do |txin|
        # Unsigned txins contain respective output scripts.
        # Signed txins contain data-only signature script (for P2PKH it is signature + pubkey)
        txin.signature_script.data_only?.must_equal true
        txin.signature_script.p2pkh?.must_equal false
      end
    end

    it "should include all prepended unspents AND all normal unspents" do
      @builder.prepended_unspent_outputs = [ BTC::TransactionOutput.new(
        value: 6_666_666,
        script: Address.parse("3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX").script,
        index: 0,
        transaction_hash: "some mock tx".hash256
      ) ]
      result = @builder.build
      result.inputs_amount.must_equal mock_utxos.inject(0){|sum, out| sum + out.value} + 6_666_666
      result.transaction.inputs.size.must_equal mock_utxos.size + 1
    end
  end




  describe "TransactionBuilder with some outputs" do
    before do
      @builder = TransactionBuilder.new
      @all_utxos = self.mock_utxos
      @builder.input_addresses = self.mock_addresses
      @builder.provider = TransactionBuilder::Provider.new do |txb|
        addrs = txb.public_addresses
        addrs.must_equal self.mock_addresses
        scripts = addrs.map{|a| a.script }.uniq
        @all_utxos.find_all{|utxo| scripts.include?(utxo.script) }
      end
      @builder.change_address = Address.parse("1CBtcGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG")
      @builder.outputs = [ TransactionOutput.new(value: 1000_500,
                            script: Address.parse("1TipsuQ7CSqfQsjA9KU5jarSB1AnrVLLo").script) ]
    end

    it "should fill unspent_outputs using provider" do
      @builder.unspent_outputs.must_equal @all_utxos
    end

    it "should have a default fee rate" do
      @builder.fee_rate.must_equal Transaction::DEFAULT_FEE_RATE
    end

    it "should compose a minimal transaction to pay necessary amount" do
      result = @builder.build
      tx = result.transaction
      tx.inputs.size.must_equal 11
      tx.outputs.size.must_equal 2 # one change address and one output address

      # Payment address
      tx.outputs.first.value.must_equal 1000_500
      tx.outputs.first.script.standard_address.to_s.must_equal "1TipsuQ7CSqfQsjA9KU5jarSB1AnrVLLo"

      # Change address
      tx.outputs.last.value.must_equal (1000_00*11 - 1000_500 - result.fee)
      tx.outputs.last.script.standard_address.to_s.must_equal "1CBtcGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG"
    end

    it "should have a list of unsigned indexes" do
      result = @builder.build
      result.unsigned_input_indexes.must_equal (0...(result.transaction.inputs.size)).to_a
    end

    it "should have a reasonable fee" do
      result = @builder.build
      size = result.transaction.data.bytesize # size of unsigned transaction
      result.fee.must_be :>=, (size / 1000)*Transaction::DEFAULT_FEE_RATE
      result.fee.must_be :<, 0.01 * BTC::COIN
    end

    it "should have valid amounts" do
      result = @builder.build
      result.inputs_amount.must_equal 11*1000_00
      result.outputs_amount.must_be :<=, result.inputs_amount
      # Balance should be correct
      result.inputs_amount.must_equal (result.outputs_amount + result.fee)
      result.transaction.inputs.each do |txin|
        # Unsigned txins contain respective output scripts.
        # Signed txins contain data-only signature script (for P2PKH it is signature + pubkey)
        txin.signature_script.data_only?.must_equal false
        txin.signature_script.p2pkh?.must_equal true
      end
    end

    it "should sign if WIFs are provided" do
      @builder.input_addresses = mock_wifs
      result = @builder.build
      result.unsigned_input_indexes.must_equal []
      result.transaction.inputs.each do |txin|
        # Unsigned txins contain respective output scripts.
        # Signed txins contain data-only signature script (for P2PKH it is signature + pubkey)
        txin.signature_script.data_only?.must_equal true
        txin.signature_script.p2pkh?.must_equal false
      end
    end

    it "should include all prepended unspents and none of normal unspents if amount is covered" do
      @builder.prepended_unspent_outputs = [ BTC::TransactionOutput.new(
        value: 6_666_666,
        script: Address.parse("3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX").script,
        index: 0,
        transaction_hash: "some mock tx".hash256
      ) ]
      result = @builder.build
      result.inputs_amount.must_equal 6_666_666
      result.transaction.inputs.size.must_equal 1
    end

    it "should include all prepended unspents and just enough of normal unspents" do
      @builder.prepended_unspent_outputs = [ BTC::TransactionOutput.new(
        value: @builder.outputs.first.value - (self.mock_utxos.first.value / 2),
        script: Address.parse("3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX").script,
        index: 0,
        transaction_hash: "some mock tx".hash256
      ) ]
      result = @builder.build
      result.inputs_amount.must_equal(@builder.outputs.first.value + (self.mock_utxos.first.value / 2))
      result.transaction.inputs.size.must_equal 2
    end
  end

  describe "TransactionBuilder edge cases" do
    before do
      @builder = TransactionBuilder.new
      @all_utxos = self.mock_utxos
      @builder.input_addresses = self.mock_addresses
      @builder.provider = TransactionBuilder::Provider.new do |txb|
        addrs = txb.public_addresses
        addrs.must_equal self.mock_addresses
        scripts = addrs.map{|a| a.script }.uniq
        @all_utxos.find_all{|utxo| scripts.include?(utxo.script) }
      end
      @builder.change_address = Address.parse("1CBtcGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG")
    end

    it "should detect missing change address" do
      @builder.change_address = nil
      lambda do
        result = @builder.build
      end.must_raise TransactionBuilder::MissingChangeAddressError
    end

    it "should detect missing unspents" do
      @builder.provider = nil
      lambda do
        result = @builder.build
      end.must_raise TransactionBuilder::MissingUnspentOutputsError
    end

    it "should detect missing unspents" do
      @builder.unspent_outputs = [ ]
      lambda do
        result = @builder.build
      end.must_raise TransactionBuilder::MissingUnspentOutputsError
    end

    it "should detect not enough unspents" do
      @builder.outputs = [ TransactionOutput.new(value: 100*COIN, script: @builder.change_address.script) ]
      lambda do
        result = @builder.build
      end.must_raise TransactionBuilder::InsufficientFundsError
    end

    it "should detect not enough unspents because of change constraints" do
      @builder.dust_change = 0 # no coins are allowed to be lost
      @builder.minimum_change = 10000
      @builder.unspent_outputs = mock_utxos[0, 1]
      @builder.outputs = [ TransactionOutput.new(value: 1000_00 - @builder.fee_rate - 10, script: @builder.change_address.script) ]
      lambda do
        result = @builder.build
      end.must_raise TransactionBuilder::InsufficientFundsError
    end

    it "should forgo change if it's below dust level" do
      @builder.dust_change = 42
      @builder.minimum_change = 1000
      @builder.unspent_outputs = mock_utxos[0, 1]
      assumed_fee = 2590 #@builder.fee_rate # we assume we'll have sub-1K transaction
      amount = 1000_00 - assumed_fee - @builder.dust_change
      @builder.outputs = [ TransactionOutput.new(value: amount, script: @builder.change_address.script) ]

      result = @builder.build
      result.fee.must_equal assumed_fee
      result.transaction.wont_equal nil
      result.transaction.outputs.size.must_equal 1
      result.transaction.outputs.first.value.must_equal amount
    end

  end

  def mock_keys
    @mock_keys ||= [
      Key.new(private_key: "Wallet1".sha256),
      Key.new(private_key: "Wallet2".sha256)
    ]
  end

  def mock_addresses
    mock_keys.map{|k| k.address }
  end

  def mock_wifs
    mock_keys.map{|k| k.to_wif_object }
  end

  def mock_utxos
    scripts = mock_addresses.map{|a| a.script }
    (0...32).map do |i|
      TransactionOutput.new(value:  100_000,
                           script: scripts[i % scripts.size],
                 transaction_hash: ((16+i).to_s(16)*32).from_hex,
                            index: i)
    end
  end

end
