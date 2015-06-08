require_relative '../spec_helper'

describe "Verifying transfer outputs" do

  def build_asset_transaction(inputs: [], issues: [], transfers: [])
    tx = Transaction.new
    script = PublicKeyAddress.new(hash: "some address".hash160).script
    inputs.each do
      tx.add_input(TransactionInput.new(previous_hash: "".sha256, previous_index: 0))
    end
    issues.each do |tuple|
      tx.add_output(TransactionOutput.new(value: 1, script: script))
    end
    qtys = issues.map{|tuple| tuple.first} + transfers.map{|tuple| tuple.first}
    tx.add_output(AssetMarker.new(quantities: qtys).output)
    transfers.each do |tuple|
      tx.add_output(TransactionOutput.new(value: 1, script: script))
    end

    atx = AssetTransaction.new(transaction: tx)
    atx.inputs.each_with_index do |ain, i|
      amount, name = inputs[i]
      if amount
        ain.asset_id = asset_id(name)
        ain.value = amount
        ain.verified = true
      else
        ain.asset_id = nil
        ain.value = nil
        ain.verified = true
      end
    end

    atx
  end

  def asset_id(name)
    name ? AssetID.new(hash: name.hash160) : nil
  end

  def asset_transfer_must_be_verified(inputs: [], issues: [], transfers: [])
    atx = build_asset_transaction(inputs: inputs, issues: issues, transfers: transfers)
    result = @processor.verify_transfers(atx)
    if !result
      # Note: when tests are executed in random order, this may contain some leftover messages from other tests.
      #$stderr << Diagnostics.current.last_message
    end
    result.must_equal true
    atx.outputs.map {|aout|
      [aout.verified?, aout.value, aout.asset_id]
    }.must_equal((issues + [nil] + transfers).map {|tuple| # [nil] for marker
      amount, name = tuple
      [true, amount, name ? asset_id(name) : nil]
    })
  end

  def asset_transfer_must_not_be_verified(inputs: [], issues: [], transfers: [])
    atx = build_asset_transaction(inputs: inputs, issues: issues, transfers: transfers)
    result = @processor.verify_transfers(atx)
    result.must_equal false
    atx.outputs.map {|aout|
      aout.verified?
    }.must_equal((issues + [nil] + transfers).map {|tuple| # [nil] for marker
        amount, name, failed = tuple
        !failed
      })
  end

  before do
    @processor = AssetProcessor.new(source: :NOT_USED)
  end

  it "should support transferring asset with overlapping and underlapping" do
    Diagnostics.current.trace do
      asset_transfer_must_be_verified(
        inputs:    [ [100, "A"], [50, "A"], [10, "A"], [30, "B"], [14, "B"] ],
        issues:    [ ],
        transfers: [ [125, "A"], [35, "A"], [44, "B"] ]
      )
    end
  end

  it "should support leftover whole assets" do
    asset_transfer_must_be_verified(
      inputs:    [ [100, "A"], [50, "A"] ],
      issues:    [ ],
      transfers: [ [100, "A"] ]
    )
  end

  it "should support leftover partial assets" do
    asset_transfer_must_be_verified(
      inputs:    [ [100, "A"], [50, "A"] ],
      issues:    [ ],
      transfers: [ [125, "A"] ]
    )
  end

  it "should fail when not enough units" do
    asset_transfer_must_not_be_verified(
      inputs:    [ [100, "A"], [100, "A"] ],
      issues:    [ ],
      transfers: [ [150, "A"], [150, "A", :fail], [50, "B", :fail] ]
    )
  end

  it "should fail when assets are mixed" do
    asset_transfer_must_not_be_verified(
      inputs:    [ [100, "A"], [100, "B"] ],
      issues:    [ ],
      transfers: [ [50, "A"], [150, "A", :fail] ]
    )
  end

end


describe "Verifying a chain of transactions" do

  class InMemoryTxSource
    include AssetProcessorSource
    def initialize
      @txs = {}
    end
    def add_transaction(tx)
      @txs[tx.transaction_hash] = tx
    end
    def transaction_for_hash(hash)
      @txs[hash]
    end
    def inspect
      "#<InMemoryTxSource:#{@txs.size} txs:\n#{@txs.map{|h,t| h.to_hex + ": #{t.inspect}" }.join("\n")}\n>"
    end
  end

  def build_asset_transaction(inputs: [], issues: [], transfers: [])
    tx = Transaction.new
    script = PublicKeyAddress.new(hash: "some address".hash160).script
    inputs.each do
      tx.add_input(TransactionInput.new(previous_hash: "".sha256, previous_index: 0))
    end
    issues.each do |tuple|
      tx.add_output(TransactionOutput.new(value: 1, script: script))
    end
    qtys = issues.map{|tuple| tuple.first} + transfers.map{|tuple| tuple.first}
    tx.add_output(AssetMarker.new(quantities: qtys).output)
    transfers.each do |tuple|
      tx.add_output(TransactionOutput.new(value: 1, script: script))
    end

    atx = AssetTransaction.new(transaction: tx)
    atx.inputs.each_with_index do |ain, i|
      amount, name = inputs[i]
      if amount
        ain.asset_id = asset_id(name)
        ain.value = amount
        ain.verified = true
      else
        ain.asset_id = nil
        ain.value = nil
        ain.verified = true
      end
    end

    atx
  end

  def asset_id(name)
    name ? AssetID.new(hash: name.hash160) : nil
  end

  def make_transaction(inputs: [], outputs: [])
    tx = Transaction.new
    inputs.each do |inp|
      txout = inp
      tx.add_input(TransactionInput.new(previous_hash: txout.transaction_hash,
                                        previous_index: txout.index))
    end
    payment_outputs = []
    issue_outputs = []
    transfer_outputs = []
    qtys = []
    outputs.each do |out|
      if out[:issue]
        issue_outputs << out
        qtys << out[:issue]
      elsif out[:transfer]
        transfer_outputs << out
        qtys << out[:transfer]
      else
        payment_outputs << out
      end
    end
    issue_outputs.each do |out|
      tx.add_output(TransactionOutput.new(value: out[:btc], script: Address.parse(out[:address]).script))
    end
    if qtys.size > 0
      tx.add_output(AssetMarker.new(quantities: qtys).output)
    end
    (transfer_outputs + payment_outputs).each do |out|
      tx.add_output(TransactionOutput.new(value: out[:btc], script: Address.parse(out[:address]).script))
    end
    tx
  end

  before do
    @source = InMemoryTxSource.new
    @processor = AssetProcessor.new(source: @source)
  end

  it "should verify a simple issuance chain (parent + child transaction)" do
    issue_address = Address.parse("3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX")
    asset_id = AssetID.new(script: issue_address.script)
    tx1 = make_transaction(outputs: [
      {btc: 10_000, address: "3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX"}
    ])
    tx2 = make_transaction(
      inputs: [
        tx1.outputs[0]
      ],
      outputs: [
        {btc: 3000, issue: 42_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 7000, address: "3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX"},
      ]
    )
    @source.add_transaction(tx1)
    atx = AssetTransaction.new(transaction: tx2)

    Diagnostics.current.trace do
      @processor.verify_asset_transaction(atx).must_equal(true)
      atx.outputs.map {|aout|
        [aout.verified?, aout.value, aout.asset_id]
      }.must_equal([
        [true, 42_000, asset_id],
        [true, nil, nil],
        [true, nil, nil],
      ])
    end
  end


  it "should verify a transfer chain" do
    issue_address = Address.parse("3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX")
    asset_id = AssetID.new(script: issue_address.script)
    tx1 = make_transaction(outputs: [
      {btc: 10_000, address: "3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX"}
    ])
    tx2 = make_transaction(
      inputs: [
        tx1.outputs[0]
      ],
      outputs: [
        {btc: 3000, issue: 42_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 7000, address: "3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX"},
      ]
    )
    tx3 = make_transaction(
      inputs: [
        tx2.outputs[0]
      ],
      outputs: [
        {btc: 3000, transfer: 10_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 3000, transfer: 32_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
      ]
    )
    tx4 = make_transaction(
      inputs: [
        # marker is output 0
        tx3.outputs[1],
        tx3.outputs[2],
      ],
      outputs: [
        {btc: 3000, transfer: 40_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 3000, transfer: 2_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
      ]
    )
    @source.add_transaction(tx1)
    @source.add_transaction(tx2)
    @source.add_transaction(tx3)
    atx = AssetTransaction.new(transaction: tx4)

    Diagnostics.current.trace do
      result = @processor.verify_asset_transaction(atx)
      result.must_equal(true)
      atx.outputs.map {|aout|
        [aout.verified?, aout.value, aout.asset_id]
      }.must_equal([
        [true, nil, nil],
        [true, 40_000, asset_id],
        [true, 2_000, asset_id],
      ])
    end
  end

  it "should fail to verify an incorrect transfer chain" do
    issue_address = Address.parse("3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX")
    asset_id = AssetID.new(script: issue_address.script)
    tx1 = make_transaction(outputs: [
      {btc: 10_000, address: "3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX"}
    ])
    tx2 = make_transaction(
      inputs: [
        tx1.outputs[0]
      ],
      outputs: [
        # HERE WE HAVE 12_000 issued instead of 42_000.
        {btc: 3000, issue: 12_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 7000, address: "3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX"},
      ]
    )
    tx3 = make_transaction(
      inputs: [
        tx2.outputs[0] # issue output
      ],
      outputs: [
        {btc: 3000, transfer: 10_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 3000, transfer: 32_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
      ]
    )
    tx4 = make_transaction(
      inputs: [
        # marker is 0
        tx3.outputs[1],
        tx3.outputs[2],
      ],
      outputs: [
        {btc: 3000, transfer: 40_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 3000, transfer: 2_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
      ]
    )
    @source.add_transaction(tx1)
    @source.add_transaction(tx2)
    @source.add_transaction(tx3)
    atx = AssetTransaction.new(transaction: tx4)

    #Diagnostics.current.trace do
      result = @processor.verify_asset_transaction(atx)
      result.must_equal(false)
      atx.outputs.map {|aout|
        [aout.verified?, aout.value, aout.asset_id]
      }.must_equal([
        [true,  nil, nil],
        [false, 40_000, nil],
        [false, 2_000, nil],
      ])
    #end
  end

  it "should verify a transfer chain with multiple assets" do
    issue_address1 = Address.parse("3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX")
    issue_address2 = Address.parse("3GkKDgJAWJnizg6Tz7DBM8uDtdHtrUkQ2X")
    asset_id1 = AssetID.new(script: issue_address1.script)
    asset_id2 = AssetID.new(script: issue_address2.script)

    tx1 = make_transaction(outputs: [
      {btc: 10_000, address: issue_address1}
    ])
    tx2 = make_transaction(outputs: [
      {btc: 10_000, address: issue_address2}
    ])
    # Issue 42K of asset 1
    tx3 = make_transaction(
      inputs: [
        tx1.outputs[0],
      ],
      outputs: [
        {btc: 3000, issue: 20_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 3000, issue: 12_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 3000, issue: 10_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
      ]
    )
    # Issue 500K of asset 2
    tx4 = make_transaction(
      inputs: [
        tx2.outputs[0],
      ],
      outputs: [
        {btc: 3000, issue: 200_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 3000, issue: 300_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
      ]
    )
    # This transfers both assets
    tx5 = make_transaction(
      inputs: [
        tx3.outputs[0],
        tx3.outputs[1],
        tx3.outputs[2],
        tx4.outputs[0],
        tx4.outputs[1],
      ],
      outputs: [
        {btc: 3000, transfer: 30_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 3000, transfer: 12_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 3000, transfer: 500_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
      ]
    )
    tx61 = make_transaction(
      inputs: [
        tx5.outputs[1],
      ],
      outputs: [
        {btc: 3000, transfer: 10_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 3000, transfer: 20_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
      ]
    )
    tx6 = (1..100).inject(tx61) do |a, _|
      b = make_transaction(
        inputs: [
          # marker is 0
          a.outputs[1],
          a.outputs[2],
        ],
        outputs: [
          {btc: 3000, transfer: 10_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
          {btc: 3000, transfer: 20_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        ]
      )
      @source.add_transaction(a)
      @source.add_transaction(b)
      b
    end

    # Issue 50K of asset 2
    tx7 = make_transaction(outputs: [
      {btc: 10_000, address: issue_address2}
    ])
    tx8 = make_transaction(
      inputs: [
        tx7.outputs[0],
      ],
      outputs: [
        {btc: 3000, issue: 1, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 3000, issue: 50_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
      ]
    )
    # Create a long chain spending from tx21
    tx9 = (1..100).inject(tx8) do |a, _|
      b = make_transaction(
        inputs: [
          # marker is 0 and for tx8 it'll use second issue output so we don't have to have special case
          a.outputs[1],
        ],
        outputs: [
          {btc: 3000, transfer: 50_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        ]
      )
      @source.add_transaction(b)
      b
    end

    # Final transaction
    tx_final = make_transaction(
      inputs: [
        tx5.outputs[3],
        tx5.outputs[2],
        tx6.outputs[2],
        tx9.outputs[1],
      ],
      outputs: [
        {btc: 3000, transfer: 500_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 3000, transfer: 30_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 3000, transfer: 2_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 3000, transfer: 50_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
      ]
    )
    @source.add_transaction(tx1)
    @source.add_transaction(tx2)
    @source.add_transaction(tx3)
    @source.add_transaction(tx4)
    @source.add_transaction(tx5)
    @source.add_transaction(tx6)
    @source.add_transaction(tx7)
    @source.add_transaction(tx8)
    @source.add_transaction(tx9)
    atx = AssetTransaction.new(transaction: tx_final)

    Diagnostics.current.trace do
      result = @processor.verify_asset_transaction(atx)
      result.must_equal(true)

      atx.outputs[0].value.must_equal nil
      atx.outputs[1].value.must_equal 500_000
      atx.outputs[2].value.must_equal 30_000
      atx.outputs[3].value.must_equal 2_000

      atx.outputs.map {|aout|
        [aout.verified?, aout.value, aout.asset_id]
      }.must_equal([
        [true, nil, nil],
        [true, 500_000, asset_id2],
        [true, 30_000, asset_id1],
        [true, 2_000, asset_id1],
        [true, 50_000, asset_id2],
      ])
    end
  end

  it "should fail to verify a mix of assets in one output" do
    issue_address1 = Address.parse("3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX")
    issue_address2 = Address.parse("3GkKDgJAWJnizg6Tz7DBM8uDtdHtrUkQ2X")
    asset_id1 = AssetID.new(script: issue_address1.script)
    asset_id2 = AssetID.new(script: issue_address2.script)

    tx1 = make_transaction(outputs: [
      {btc: 10_000, address: issue_address1}
    ])
    tx2 = make_transaction(outputs: [
      {btc: 10_000, address: issue_address2}
    ])
    # Issue 42K of asset 1
    tx3 = make_transaction(
      inputs: [
        tx1.outputs[0],
      ],
      outputs: [
        {btc: 3000, issue: 20_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 3000, issue: 12_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 3000, issue: 10_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
      ]
    )
    # Issue 500K of asset 2
    tx4 = make_transaction(
      inputs: [
        tx2.outputs[0],
      ],
      outputs: [
        {btc: 3000, issue: 200_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 3000, issue: 300_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
      ]
    )
    # This transfers both assets
    tx5 = make_transaction(
      inputs: [
        tx3.outputs[0],
        tx3.outputs[1],
        tx3.outputs[2],
        tx4.outputs[0],
        tx4.outputs[1],
      ],
      outputs: [
        {btc: 3000, transfer: 30_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},

        # This one tries to get two kinds of assets in the same output.
        {btc: 3000, transfer: 112_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
        {btc: 3000, transfer: 400_000, address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"},
      ]
    )
    @source.add_transaction(tx1)
    @source.add_transaction(tx2)
    @source.add_transaction(tx3)
    @source.add_transaction(tx4)
    atx = AssetTransaction.new(transaction: tx5)

    #Diagnostics.current.trace do
      result = @processor.verify_asset_transaction(atx)
      result.must_equal(false)
      atx.outputs.map {|aout|
        [aout.verified?, aout.value, aout.asset_id]
      }.must_equal([
        [true, nil, nil],
        [true, 30_000, asset_id1],
        [false, 112_000, asset_id1],
        [false, 400_000, nil],
      ])
    #end
  end
end
