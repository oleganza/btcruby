require_relative 'spec_helper'
describe BTC::Base58 do

  def check_invalid_base58(base58_string, expected_class = BTC::FormatError)
    lambda { Base58.data_from_base58(base58_string) }.must_raise expected_class
  end

  def check_invalid_base58check(base58check_string, expected_class = BTC::FormatError)
    lambda { Base58.data_from_base58check(base58check_string) }.must_raise expected_class
  end

  def check_valid_base58(hex_string, base58_string)
    # Convert to Base58
    Base58.base58_from_data(BTC.from_hex(hex_string)).must_equal(base58_string)

    # Convert from Base58
    BTC.to_hex(Base58.data_from_base58(base58_string)).must_equal(hex_string)
  end

  def check_valid_base58check(hex, string)
    # Convert to Base58Check
    Base58.base58check_from_data(BTC.from_hex(hex)).must_equal(string)

    # Convert from Base58Check
    BTC.to_hex(Base58.data_from_base58check(string)).must_equal(hex)
  end

  describe "Base58" do
    it "should handle valid input" do

      lambda { Base58.data_from_base58(nil) }.must_raise ArgumentError
      lambda { Base58.base58_from_data(nil) }.must_raise ArgumentError
      check_valid_base58("", "")
      check_valid_base58("13", "L")
      check_valid_base58("2e", "o")
      check_valid_base58("61", "2g")
      check_valid_base58("626262", "a3gV")
      check_valid_base58("636363", "aPEr")
      check_valid_base58("73696d706c792061206c6f6e6720737472696e67", "2cFupjhnEsSn59qHXstmK2ffpLv2")
      check_valid_base58("00eb15231dfceb60925886b67d065299925915aeb172c06647", "1NS17iag9jJgTHD1VXjvLCEnZuQ3rJDE9L")
      check_valid_base58("516b6fcd0f", "ABnLTmg")
      check_valid_base58("bf4f89001e670274dd", "3SEo3LWLoPntC")
      check_valid_base58("572e4794", "3EFU7m")
      check_valid_base58("ecac89cad93923c02321", "EJDM8drfXA6uyA")
      check_valid_base58("10c8511e", "Rt5zm")
      check_valid_base58("00000000000000000000", "1111111111")
    end

    it "should handle invalid input" do
      check_invalid_base58(nil, ArgumentError);
      check_invalid_base58(" ");
      check_invalid_base58("lLoO");
      check_invalid_base58("l");
      check_invalid_base58("O");
      check_invalid_base58("öまи");
    end
  end

  describe "Base58Check" do

    it "should handle valid input" do
      check_valid_base58check("", "3QJmnh")
      check_valid_base58check("007ab89f9fae3f8043dcee5f7b5467a0f0a6e2f7e1", "1CBtcGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG")
    end

    it "should handle invalid input" do
      check_invalid_base58check(nil, ArgumentError);
      check_invalid_base58check(" ");
      check_invalid_base58check("lLoO");
      check_invalid_base58check("l");
      check_invalid_base58check("O");
      check_invalid_base58check("öまи");
    end
    it "should detect incorrect checksum" do
      check_invalid_base58check("L");
      check_invalid_base58check("o");
      check_invalid_base58check("0CBtcGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG");
      check_invalid_base58check("2CBtcGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG");
      check_invalid_base58check("11BtcGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG");
      check_invalid_base58check("1CBtcGivXmHQ8ZqdPgeMfcpQNJrqTrSAbG");
    end
  end
end