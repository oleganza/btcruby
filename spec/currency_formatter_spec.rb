require_relative 'spec_helper'

describe BTC::CurrencyFormatter do

  it "should support normal bitcoin formatting" do
    fm = BTC::CurrencyFormatter.btc_formatter

    fm.string_from_number(1*BTC::COIN).must_equal("1.0")
    fm.string_from_number(42*BTC::COIN).must_equal("42.0")
    fm.string_from_number(42000*BTC::COIN).must_equal("42000.0")
    fm.string_from_number(42000*BTC::COIN + 123).must_equal("42000.00000123")
    fm.string_from_number(42000*BTC::COIN + 123000).must_equal("42000.00123")
    fm.string_from_number(42000*BTC::COIN + 123456).must_equal("42000.00123456")
    fm.string_from_number(42000*BTC::COIN + BTC::COIN/2).must_equal("42000.5")

    fm.number_from_string("1").must_equal 1*BTC::COIN
    fm.number_from_string("1.0").must_equal 1*BTC::COIN
    fm.number_from_string("42").must_equal 42*BTC::COIN
    fm.number_from_string("42.123").must_equal 42*BTC::COIN + 12300000
    fm.number_from_string("42.12345678").must_equal 42*BTC::COIN + 12345678
    fm.number_from_string("42.10000000").must_equal 42*BTC::COIN + 10000000
    fm.number_from_string("42.10000").must_equal    42*BTC::COIN + 10000000
  end

  it "should support long bitcoin formatting" do
    fm = BTC::CurrencyFormatter.btc_long_formatter

    fm.string_from_number(1*BTC::COIN).must_equal("1.00000000")
    fm.string_from_number(42*BTC::COIN).must_equal("42.00000000")
    fm.string_from_number(42000*BTC::COIN).must_equal("42000.00000000")
    fm.string_from_number(42000*BTC::COIN + 123).must_equal("42000.00000123")
    fm.string_from_number(42000*BTC::COIN + 123000).must_equal("42000.00123000")
    fm.string_from_number(42000*BTC::COIN + 123456).must_equal("42000.00123456")
    fm.string_from_number(42000*BTC::COIN + BTC::COIN/2).must_equal("42000.50000000")

    fm.number_from_string("1").must_equal 1*BTC::COIN
    fm.number_from_string("1.0").must_equal 1*BTC::COIN
    fm.number_from_string("42").must_equal 42*BTC::COIN
    fm.number_from_string("42.123").must_equal 42*BTC::COIN + 12300000
    fm.number_from_string("42.12345678").must_equal 42*BTC::COIN + 12345678
    fm.number_from_string("42.10000000").must_equal 42*BTC::COIN + 10000000
    fm.number_from_string("42.10000").must_equal    42*BTC::COIN + 10000000
  end
end
