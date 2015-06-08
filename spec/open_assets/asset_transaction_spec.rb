require_relative '../spec_helper'

describe "Serialization" do

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
    
  before do
    @atx = build_asset_transaction(
      inputs:    [ [100, "A"], [30, "B"], [14, "B"] ],
      issues:    [ ],
      transfers: [ [40, "A"], [60, "A"], [44, "B"] ]
    )
    data = @atx.data
    @atx2 = AssetTransaction.new(data: data)
  end
  
  it "should restore all outputs" do 
    @atx.inputs.each_with_index do |ain1, i|
      ain2 = @atx2.inputs[i]
      ain1.verified?.must_equal ain2.verified?
      ain1.verified?.must_equal true
      ain1.asset_id.must_equal ain2.asset_id
      ain1.value.must_equal ain2.value
    end
    @atx.outputs.each_with_index do |aout1, i|
      aout2 = @atx2.outputs[i]
      aout1.verified?.must_equal aout2.verified?
      aout1.verified?.must_equal aout1.marker?
      aout1.asset_id.must_equal aout2.asset_id
      aout1.asset_id.must_equal nil
      aout1.value.must_equal aout2.value
    end
  end
  
  
end