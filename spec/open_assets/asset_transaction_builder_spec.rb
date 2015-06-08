require_relative '../spec_helper'

describe BTC::AssetTransactionBuilder do

  class SignerByKey
    include TransactionBuilder::Signer
    def initialize(&block)
      @block = block
    end
    def signing_key_for_output(output: nil, address: nil)
      @block.call(output, address)
    end
  end

  describe "Issuing an asset with two transactions" do

    before do
      builder = BTC::AssetTransactionBuilder.new

      @all_wallet_utxos = self.mock_wallet_utxos
      builder.bitcoin_provider = TransactionBuilder::Provider.new do |txb|
        @all_wallet_utxos
      end
      builder.signer = SignerByKey.new do |output, address|
        mock_all_keys.find{|k| k.address == address }
      end

      # We want to issue 1M units to one address and 50K units for another.
      # OpenAssets does not allow issuing different assets in one Asset Transaction because Asset ID is determined by the first input.
      builder.issue_asset(source_script: issuer1_key.address.script, amount: 1000_000, address: holder1_asset_address)
      builder.issue_asset(source_script: issuer1_key.address.script, amount: 50_000, address: holder2_asset_address)

      # Just some payment to add.
      builder.send_bitcoin(amount: 100, address: wallet1_key.address)

      # Send btc change to this address.
      builder.bitcoin_change_address = wallet2_key.address

      # Send leftover assets to this address.
      builder.asset_change_address = holder2_asset_address

      # Build transactions.
      @builder = builder
      @result = builder.build
    end

    it "should have two transactions: asset definition and issuance" do
      @result.transactions.size.must_equal(2)
    end

    it "should have last transaction wrapped in AssetTransaction" do
      @result.asset_transaction.transaction.must_equal(@result.transactions.last)
    end

    it "should have two transactions linked up" do
      @result.transactions.last.inputs.first.previous_hash.must_equal @result.transactions.first.transaction_hash
    end

    it "should have first transaction uncolored" do
      @result.transactions.first.open_assets_transaction?.must_equal false
    end

    it "should have second transaction with colored outputs" do
      @result.transactions.last.open_assets_transaction?.must_equal true
      @result.asset_transaction.inputs.each do |ain|
        ain.colored?.must_equal false
        ain.verified?.must_equal true
      end
      @result.asset_transaction.outputs.each_with_index do |aout, i|
        aout.colored?.must_equal(i < 2) # only first 2 outputs are colored because they issue asset
        aout.verified?.must_equal true
      end
    end

    it "should have an asset cost of two issuances" do
      @result.assets_cost.must_equal 546*2
    end
  end

  describe "Issuing an asset with an existing source output" do
  end

  describe "Transferring a few assets" do
    before do

      builder = BTC::AssetTransactionBuilder.new

      @all_wallet_utxos = self.mock_wallet_utxos
      builder.bitcoin_provider = TransactionBuilder::Provider.new do |txb|
        @all_wallet_utxos
      end
      builder.signer = SignerByKey.new do |output, address|
        mock_all_keys.find{|k| k.address == address }
      end

      # We want to be able to swap assets: when one user provides Apples and the other provides Oranges.
      # Each transfer may have its own unspents and its own change address.
      # If those are not specified, a per-builder setting is chosen.

      @asset1 = AssetID.new(script: Script.new << OP_1)
      @asset2 = AssetID.new(script: Script.new << OP_2)

      builder.transfer_asset(
        asset_id: @asset1,
        amount: 10_000,
        address: holder2_asset_address,
        unspent_outputs: [
          AssetTransactionOutput.new(
            transaction_output: mock_utxo(value: 1000),
            asset_id: @asset1,
            value: 11_000,
            transfer: true,
            verified: true,
          )
        ],
        change_address: holder1_asset_address
      )

      builder.transfer_asset(
        asset_id: @asset2,
        amount: 50_000,
        address: holder1_asset_address,
        unspent_outputs: [
          AssetTransactionOutput.new(
            transaction_output: mock_utxo(value: 1000),
            asset_id: @asset2,
            value: 150_000,
            transfer: true,
            verified: true,
          )
        ],
        change_address: holder2_asset_address
      )

      # Send btc change to this address.
      builder.bitcoin_change_address = wallet2_key.address

      # Send leftover assets to this address.
      builder.asset_change_address = AssetAddress.new(bitcoin_address: holder2_key.address)

      # Build transactions.
      @builder = builder
      @result = builder.build
    end

    it "should have two change outputs: for each transfer" do
      @result.asset_transaction.outputs.size.must_equal(1 + 2 + 2 + 1)
      marker, transfer1, change1, transfer2, change2, btcchange = @result.asset_transaction.outputs

      transfer1.transfer?.must_equal true
      transfer1.value.must_equal 10_000
      change1.transfer?.must_equal true
      change1.value.must_equal 1_000
      transfer1.asset_id.to_s.must_equal change1.asset_id.to_s
      transfer1.asset_id.to_s.must_equal @asset1.to_s
      transfer1.transaction_output.script.standard_address.to_s.must_equal holder2_key.address.to_s
      change1.transaction_output.script.standard_address.to_s.must_equal holder1_key.address.to_s

      transfer2.transfer?.must_equal true
      transfer2.value.must_equal 50_000
      change2.transfer?.must_equal true
      change2.value.must_equal 100_000
      transfer2.asset_id.to_s.must_equal change2.asset_id.to_s
      transfer2.asset_id.to_s.must_equal @asset2.to_s
      transfer2.transaction_output.script.standard_address.to_s.must_equal holder1_key.address.to_s
      change2.transaction_output.script.standard_address.to_s.must_equal holder2_key.address.to_s

      btcchange.colored?.must_equal false
      btcchange.verified?.must_equal true
      btcchange.asset_id.must_equal nil
    end
  end

  # Mocked wallet

  def wallet1_key
    @wallet1_key ||= Key.new(private_key: "Wallet1".sha256)
  end

  def wallet2_key
    @wallet2_key ||= Key.new(private_key: "Wallet2".sha256)
  end

  def issuer1_key
    @issuer1_key ||= Key.new(private_key: "Issuer1".sha256)
  end

  def issuer2_key
    @issuer2_key ||= Key.new(private_key: "Issuer2".sha256)
  end

  def holder1_key
    @holder1_key ||= Key.new(private_key: "Holder1".sha256)
  end

  def holder2_key
    @holder2_key ||= Key.new(private_key: "Holder2".sha256)
  end

  def holder1_asset_address
    AssetAddress.new(bitcoin_address: holder1_key.address)
  end

  def holder2_asset_address
    AssetAddress.new(bitcoin_address: holder2_key.address)
  end

  def mock_wallet_keys
    @mock_wallet_keys ||= [wallet1_key, wallet2_key]
  end

  def mock_all_keys
    @mock_all_keys ||= [wallet1_key, wallet2_key,
                        issuer1_key, issuer2_key,
                        holder1_key, holder2_key]
  end

  def mock_wallet_addresses
    mock_wallet_keys.map{|k| k.address }
  end

  def mock_wallet_utxos
    scripts = mock_wallet_addresses.map{|a| a.script }
    (1..32).map do |i|
      TransactionOutput.new(value:  100_000,
                           script: scripts[i % scripts.size],
                 transaction_hash: ((16+i).to_s(16)*32).from_hex,
                            index: i)
    end
  end

  def mock_utxo(value: 100_000, index: 0, script: Script.new << OP_1)
    TransactionOutput.new(value: value,
                         script: script,
               transaction_hash: Key.random.private_key.sha256,
                          index: index)
  end

  def mock_asset_utxos

  end

end

# Temporary test
describe "Issuing an asset" do

  it "should issue a new asset from a given tx output" do
    issuer = BTC::Key.new(private_key: "Treasury Key".sha256)
    holder = BTC::Key.new(private_key: "Chancellor Key".sha256)

    issuing_script = issuer.address.script
    holding_script = holder.address.script

    source_output = TransactionOutput.new(value: 100, script: issuing_script)

    # These are set automatically if source_output is a part of some BTC::Transaction
    # We need these to complete the input for the transfer transaction.
    source_output.transaction_hash = BTC::Data.hash256("some tx")
    source_output.index = 0

    transfer = Transaction.new
    transfer.add_input(TransactionInput.new(transaction_output: source_output))
    transfer.add_output(TransactionOutput.new(value: source_output.value, script: holding_script))
    marker = AssetMarker.new
    marker.quantities = [ 1000_000_000 ]
    marker.metadata = "Chancellor bailing out banks"
    transfer.outputs << marker.output
  end

end


