require_relative 'spec_helper'

describe BTC::Data do

  it "should decode valid hex" do
    lambda { BTC::Data.data_from_hex(nil) }.must_raise ArgumentError
    BTC::Data.data_from_hex("fe").bytes.must_equal "\xfe".bytes
    BTC::Data.data_from_hex("deadBEEF").bytes.must_equal "\xde\xad\xbe\xef".bytes
    BTC::Data.data_from_hex("   \r\n\tdeadBEEF  \t \r \n").bytes.must_equal "\xde\xad\xbe\xef".bytes
    BTC::Data.data_from_hex("").bytes.must_equal "".bytes
    BTC::Data.data_from_hex("  \t  ").bytes.must_equal "".bytes
  end

  it "should not decode invalid hex" do
    lambda { BTC::Data.data_from_hex("f") }.must_raise FormatError
    lambda { BTC::Data.data_from_hex("dxadBEEF") }.must_raise FormatError
    lambda { BTC::Data.data_from_hex("-") }.must_raise FormatError
  end

  it "should encode valid hex" do
    lambda { BTC::Data.hex_from_data(nil) }.must_raise ArgumentError
    BTC::Data.hex_from_data("\xfe").bytes.must_equal "fe".bytes
    BTC::Data.hex_from_data("\xde\xad\xbe\xef").bytes.must_equal "deadbeef".bytes
    BTC::Data.hex_from_data("").bytes.must_equal "".bytes
  end

  it "should encode bytes" do
    BTC::Data.bytes_from_data("Hello, world").must_equal "Hello, world".bytes
    BTC::Data.bytes_from_data("Hello, world").must_equal [72, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100]
    BTC::Data.data_from_bytes([72, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100]).must_equal "Hello, world"
  end

  it "should access ranges of bytes" do
    BTC::Data.bytes_from_data("Hello, world", offset: 1).must_equal "ello, world".bytes
    BTC::Data.bytes_from_data("Hello, world", offset: 0, limit: 3).must_equal "Hel".bytes

    # Range takes precedence over offset/limit.
    BTC::Data.bytes_from_data("Hello, world", offset: 0, limit: 3, range: 1..2).must_equal "el".bytes

    BTC::Data.bytes_from_data("Hello, world", range: 1..3).must_equal "ell".bytes
    BTC::Data.bytes_from_data("Hello, world", range: 1...3).must_equal "el".bytes

    # Outside bounds
    BTC::Data.bytes_from_data("Hello, world", offset: 110, limit: 3).must_equal []
    BTC::Data.bytes_from_data("Hello, world", offset: 0, limit: 0).must_equal   []
    BTC::Data.bytes_from_data("Hello, world", range: 100..101).must_equal       []
    BTC::Data.bytes_from_data("Hello, world", range: 0...0).must_equal          []
  end

end
