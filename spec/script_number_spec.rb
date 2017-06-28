require_relative 'spec_helper'

describe BTC::ScriptNumber do

  [-1000000000000000,-10000,-100,-1,0,1,10,1000,100000000000000].each do |i|
    it "should return integer #{i} as-is after a round-trip" do
      BTC::ScriptNumber.new(integer: i).to_i.must_equal i
    end
  end

  it "should validate a range of back-and-forth conversions" do
    (-100000..10000).each do |i|
      BTC::ScriptNumber.new(integer: i).to_i.must_equal i
    end
  end

  it "should parse empty string as zero" do
    BTC::ScriptNumber.new(data: "").to_i.must_equal 0
  end

  it "should parse 0x01 as 1" do
    BTC::ScriptNumber.new(data: "\x01").to_i.must_equal 1
  end

  it "should parse 0x27 as 39" do
    BTC::ScriptNumber.new(data: "\x27").to_i.must_equal 39
  end

  it "should parse 0xff as -127" do
    BTC::ScriptNumber.new(data: "\xff").to_i.must_equal -127
  end

  it "should parse 0xff00 as 255." do
    BTC::ScriptNumber.new(data: "\xff\x00").to_i.must_equal 255
  end

  it "should parse 0x81 as -1." do
    BTC::ScriptNumber.new(data: "\x81").to_i.must_equal -1
  end

  it "should parse 0x8f as -0x0f." do
    BTC::ScriptNumber.new(data: "\x8f").to_i.must_equal -15
  end

  it "should parse 0x0081 as -256." do
    BTC::ScriptNumber.new(data: "\x00\x81").to_i.must_equal -256
  end

  it "should decode -255." do
    BTC::ScriptNumber.new(data: "\xff\x80").to_i.must_equal -255
  end

  it "should raise exception for non-minimally-encoded data" do
    should_raise('non-minimally encoded script number') { BTC::ScriptNumber.new(data: "\x00") }
    should_raise('non-minimally encoded script number') { BTC::ScriptNumber.new(data: "\x80") }
    should_raise('non-minimally encoded script number') { BTC::ScriptNumber.new(data: "\x00\x80") }
    should_raise('non-minimally encoded script number') { BTC::ScriptNumber.new(data: "\x01\x80") }
    should_raise('non-minimally encoded script number') { BTC::ScriptNumber.new(data: "\x00\x00\x80") }
    should_raise('non-minimally encoded script number') { BTC::ScriptNumber.new(data: "\x00\x10\x80") }
    should_raise('non-minimally encoded script number') { BTC::ScriptNumber.new(data: "\x10\x00\x80") }
  end

  it "should raise exception for invalid encoding" do
    should_raise('script number overflow (3 > 2)')      { BTC::ScriptNumber.new(data: "\x00\x00\x80", max_size: 2) }
  end

  it "should encode booleans" do
    BTC::ScriptNumber.new(boolean: true).must_equal 1
    BTC::ScriptNumber.new(boolean: true).data.must_equal "\x01"
    BTC::ScriptNumber.new(boolean: false).must_equal 0
    BTC::ScriptNumber.new(boolean: false).data.must_equal ""
  end

  it "should check equality checks" do
    (BTC::ScriptNumber.new(integer: 0) == 0).must_equal true
    (BTC::ScriptNumber.new(integer: 1) == 1).must_equal true
    (BTC::ScriptNumber.new(integer: -1) == -1).must_equal true

    (BTC::ScriptNumber.new(integer: 0) == BTC::ScriptNumber.new(integer: 0)).must_equal true
    (BTC::ScriptNumber.new(integer: 1) == BTC::ScriptNumber.new(integer: 1)).must_equal true
    (BTC::ScriptNumber.new(integer: -1) == BTC::ScriptNumber.new(integer: -1)).must_equal true

    (BTC::ScriptNumber.new(integer: 0) != 0).must_equal false
    (BTC::ScriptNumber.new(integer: 1) != 1).must_equal false
    (BTC::ScriptNumber.new(integer: -1) != -1).must_equal false
    (BTC::ScriptNumber.new(integer: 0) != BTC::ScriptNumber.new(integer: 0)).must_equal false
    (BTC::ScriptNumber.new(integer: 1) != BTC::ScriptNumber.new(integer: 1)).must_equal false
    (BTC::ScriptNumber.new(integer: -1) != BTC::ScriptNumber.new(integer: -1)).must_equal false
  end

  it "should support #-" do
    sn = BTC::ScriptNumber.new(integer: 123)
    sn = sn - 20
    sn -= 3
    sn.must_equal 100
  end

  it "should support #+" do
    sn = BTC::ScriptNumber.new(integer: 123)
    sn = sn + 20
    sn += 7
    sn.must_equal 150
  end

  it "should support unary minus operator" do
    sn = BTC::ScriptNumber.new(integer: 123)
    sn = -sn
    sn.must_equal -123
  end

  it "should support unary plus operator" do
    sn = BTC::ScriptNumber.new(integer: 123)
    sn = +sn
    sn.must_equal 123
  end

  it "should support #*" do
    sn = BTC::ScriptNumber.new(integer: 123)
    sn = sn * 10
    sn.must_equal 1230

    sn = BTC::ScriptNumber.new(integer: 123)
    sn = sn * -10
    sn.must_equal -1230

    sn = BTC::ScriptNumber.new(integer: -123)
    sn = sn * 10
    sn.must_equal -1230

    sn = BTC::ScriptNumber.new(integer: -123)
    sn = sn * -10
    sn.must_equal 1230
  end

  it "should support integer #/ rounding to a lower value" do
    sn = BTC::ScriptNumber.new(integer: 123)
    sn = sn / 10
    sn.must_equal 12

    sn = BTC::ScriptNumber.new(integer: 123)
    sn = sn / -10
    sn.must_equal -13

    sn = BTC::ScriptNumber.new(integer: -123)
    sn = sn / -10
    sn.must_equal 12

    sn = BTC::ScriptNumber.new(integer: -123)
    sn = sn / 10
    sn.must_equal -13
  end

  it "should support << (LSHIFT)" do
    sn = BTC::ScriptNumber.new(integer: 123)
    sn = sn << 0
    sn.must_equal 123

    sn = BTC::ScriptNumber.new(integer: 123)
    sn = sn << 2
    sn.must_equal 492
  end

  it "should support >> (RSHIFT) with overflow" do
    sn = BTC::ScriptNumber.new(integer: 123)
    sn = sn >> 0
    sn.must_equal 123

    sn = BTC::ScriptNumber.new(integer: 123)
    sn = sn >> 1
    sn.must_equal 61

    sn = BTC::ScriptNumber.new(integer: -123)
    sn = sn >> 1
    sn.must_equal -61

    sn = BTC::ScriptNumber.new(integer: 123)
    sn = sn >> 7
    sn.must_equal 0

    sn = BTC::ScriptNumber.new(integer: -123)
    sn = sn >> 7
    sn.must_equal 0
  end

  def should_raise(message)
    raised = false
    begin
      yield
    rescue => e
      if e.message == message
        raised = true
      else
        raise "Raised unexpected exception: #{e}"
      end
    end
    if !raised
      raise "Should have raised #{message.inspect}!"
    end
  end
end