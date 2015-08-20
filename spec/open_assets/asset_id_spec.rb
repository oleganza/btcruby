require_relative '../spec_helper'

describe BTC::AssetID do
  it "should encode script to a correct address" do
    key = BTC::Key.new(private_key: "18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725".from_hex, public_key_compressed: false)
    asset_id = BTC::AssetID.new(script: key.address(network: BTC::Network.mainnet).script, network: BTC::Network.mainnet)
    asset_id.to_s.must_equal "ALn3aK1fSuG27N96UGYB1kUYUpGKRhBuBC"
    asset_id.is_a?(BTC::AssetID).must_equal true
  end
  it "should decode an asset address" do
    asset_id = BTC::Address.parse("ALn3aK1fSuG27N96UGYB1kUYUpGKRhBuBC")
    asset_id.is_a?(BTC::AssetID).must_equal true
    asset_id.hash.must_equal "36e0ea8e93eaa0285d641305f4c81e563aa570a2".from_hex
  end
end
