require_relative '../spec_helper'

describe BTC::IssuanceID do
  it "should encode script to a correct address" do
    key = BTC::Key.new(private_key: "18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725".from_hex, public_key_compressed: false)
    issuance_id = BTC::IssuanceID.new(outpoint: BTC::Outpoint.new(transaction_hash: BTC.hash256("tx1"), index:1), network: BTC::Network.mainnet)
    issuance_id.hash.to_hex.must_equal "601a635e4f95178e999b9957cc8cea255e988a4f"
    issuance_id.to_s.must_equal "SW49WjotbWmG4GMWXZmpP3bdCrABmC8LRG"
    issuance_id.is_a?(BTC::IssuanceID).must_equal true
  end
  it "should decode an asset address" do
    issuance_id = BTC::Address.parse("SW49WjotbWmG4GMWXZmpP3bdCrABmC8LRG")
    issuance_id.is_a?(BTC::IssuanceID).must_equal true
    issuance_id.hash.to_hex.must_equal "601a635e4f95178e999b9957cc8cea255e988a4f"
  end
end
