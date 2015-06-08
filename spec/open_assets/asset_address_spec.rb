require_relative '../spec_helper'

describe BTC::AssetAddress do
  it "should encode bitcoin address to a correct asset address" do
    btc_address = Address.parse("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM")
    asset_address = AssetAddress.new(bitcoin_address: btc_address)
    asset_address.bitcoin_address.must_equal btc_address
    asset_address.to_s.must_equal "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"
    asset_address.mainnet?.must_equal true
  end
  it "should decode an asset address" do
    asset_address = Address.parse("akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy")
    asset_address.bitcoin_address.to_s.must_equal "16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM"
    asset_address.mainnet?.must_equal true
  end
  it "should allow instantiating Asset Address with an Asset Address" do
    asset_address = AssetAddress.new(bitcoin_address: "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy")
    asset_address.to_s.must_equal "akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy"
    asset_address.bitcoin_address.to_s.must_equal "16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM"
    asset_address.mainnet?.must_equal true
  end
  it "should support P2SH address for assets" do
    asset_address = AssetAddress.new(bitcoin_address: "3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX")
    asset_address.to_s.must_equal "anQin2TDYaubr6M5MQM8kNXMitHc2hsmfGc"
    asset_address.bitcoin_address.to_s.must_equal "3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX"
    asset_address.mainnet?.must_equal true

    asset_address = Address.parse("anQin2TDYaubr6M5MQM8kNXMitHc2hsmfGc")
    asset_address.class.must_equal(AssetAddress)
    asset_address.bitcoin_address.to_s.must_equal "3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX"
    asset_address.mainnet?.must_equal true
  end
end
