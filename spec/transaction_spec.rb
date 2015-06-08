require_relative 'spec_helper'
describe BTC::Transaction do

  it "should have core attributes" do

    tx = BTC::Transaction.new

    tx.data.to_hex.must_equal("01000000" + "0000" + "00000000")

    tx.to_h.must_equal({
      "hash"=>"d21633ba23f70118185227be58a63527675641ad37967e2aa461559f577aec43",
      "ver"=>1,
      "vin_sz"=>0,
      "vout_sz"=>0,
      "lock_time"=>0,
      "size"=>10,
      "in"=>[],
      "out"=>[]
    })

  end

  describe "Hash <-> ID conversion" do
    before do
      @txid   = "43ec7a579f5561a42a7e9637ad4156672735a658be2752181801f723ba3316d2"
      @txhash = @txid.from_hex.reverse
    end

    it "should convert tx ID to binary hash" do
      BTC.hash_from_id(nil).must_equal nil
      BTC.hash_from_id(@txid).must_equal @txhash
    end

    it "should convert binary hash to tx ID" do
      BTC.id_from_hash(nil).must_equal nil
      BTC.id_from_hash(@txhash).must_equal @txid
    end

    it "should convert hash to/from id for TransactionOutput" do
      txout = TransactionOutput.new
      txout.transaction_hash = @txhash
      txout.transaction_id.must_equal @txid
      txout.transaction_id = "deadbeef"
      txout.transaction_hash.to_hex.must_equal "efbeadde"
    end
  end


  describe "Amounts calculation" do
    before do
      @tx = Transaction.new
      @tx.add_input(TransactionInput.new)
      @tx.add_input(TransactionInput.new)
      @tx.add_output(TransactionOutput.new(value: 123))
      @tx.add_output(TransactionOutput.new(value: 50_000))
    end

    it "should have good defaults" do
      @tx.inputs_amount.must_equal nil
      @tx.fee.must_equal nil
      @tx.outputs_amount.must_equal 50_123
    end

    it "should derive inputs_amount from fee" do
      @tx.fee = 10_000
      @tx.fee.must_equal 10_000
      @tx.inputs_amount.must_equal 60_123
      @tx.outputs_amount.must_equal 50_123
    end

    it "should derive fee from inputs_amount" do
      @tx.inputs_amount = 55_123
      @tx.fee.must_equal 5_000
      @tx.inputs_amount.must_equal 55_123
      @tx.outputs_amount.must_equal 50_123
    end

    it "should derive inputs_amount from input values if present" do
      @tx.inputs[0].value = 50_523
      @tx.inputs[1].value = 100
      @tx.fee.must_equal 500
      @tx.inputs_amount.must_equal 50_623
      @tx.outputs_amount.must_equal 50_123
    end

    it "should not derive inputs_amount from input values if some value is nil" do
      @tx.inputs[0].value = 50_523
      @tx.inputs[1].value = nil
      @tx.fee.must_equal nil
      @tx.inputs_amount.must_equal nil
      @tx.outputs_amount.must_equal 50_123
    end
  end


  describe "Certain transaction" do

    before do
      @txdata =("0100000001dfb32e172d6cdc51215c28b83415f977fc6ce281e057f7cf40c700" +
                "8003f7230f000000008a47304402207f5561ac3cfb05743cab6ca914f7eb93c4" +
                "89f276f10cdf4549e7f0b0ef4e85cd02200191c0c2fd10f10158973a0344fdaf" +
                "2438390e083a509d2870bcf2b05445612b0141043304596050ca119efccada1d" +
                "d7ca8e511a76d8e1ddb7ad050298d208455b8bcd09593d823ca252355bf0b41c" +
                "2ac0ba2afa7ada4660bd38e27585aac7d4e6e435ffffffff02c0791817000000" +
                "0017a914bd224370f93a2b0435ded92c7f609e71992008fc87ac7b4d1d000000" +
                "001976a914450c22770eebb00d376edabe7bb548aa64aa235688ac00000000").from_hex
      @tx = Transaction.new(hex: @txdata.to_hex)
      @tx = Transaction.new(data: @txdata)
    end

    it "should decode inputs and outputs correctly" do
      @tx.version.must_equal 1
      @tx.lock_time.must_equal 0
      @tx.inputs.size.must_equal 1
      @tx.outputs.size.must_equal 2
      @tx.transaction_id.must_equal "f2d0daf07409e44216fe71075df88f3c8c0c5f8e313582ab256e7af2765dd14e"
    end

    it "should support dup" do
      @tx2 = @tx.dup
      @tx2.data.must_equal @txdata
      @tx2.must_equal @tx
      @tx2.object_id.wont_equal @tx.object_id
    end

    it "detect script kinds" do
      @tx.outputs[0].script.standard?.must_equal true
      @tx.outputs[0].script.script_hash_script?.must_equal true

      @tx.outputs[1].script.standard?.must_equal true
      @tx.outputs[1].script.public_key_hash_script?.must_equal true
    end

    it "input script should have a valid signature" do

      @tx.inputs.first.signature_script.to_a.map{|c|c.to_hex}.must_equal [
        "304402207f5561ac3cfb05743cab6ca914f7eb93c489f276f10cdf4549e7f0b0ef4e85cd02200191c0c2fd10f10158973a0344fdaf2438390e083a509d2870bcf2b05445612b01",
        "043304596050ca119efccada1dd7ca8e511a76d8e1ddb7ad050298d208455b8bcd09593d823ca252355bf0b41c2ac0ba2afa7ada4660bd38e27585aac7d4e6e435"
      ]

      Diagnostics.current.trace do
        BTC::Key.validate_script_signature(@tx.inputs.first.signature_script.to_a[0], verify_lower_s: true).must_equal true
      end
    end

  end

  describe "Coinbase Transaction" do
    before do
      @txdata =("0100000001000000000000000000000000000000000000000000000000000000" +
                "0000000000ffffffff130301e6040654188d181202119700de00000fccffffff" +
                "ff0108230595000000001976a914ca6ecc7d4d671d8c5c964a48dbb0bc194407" +
                "a30688ac00000000").from_hex
      @tx = Transaction.new(data: @txdata)
    end

    it "should encode coinbase inputs correctly" do
      @tx.data.must_equal @txdata
    end
  end

end
