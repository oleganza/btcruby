require_relative 'spec_helper'
describe BTC::BlockHeader do

  describe "Genesis Mainnet" do
    it "should have a correct hash" do
      BlockHeader.genesis_mainnet.block_id.must_equal "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f"
      BlockHeader.genesis_mainnet.height.must_equal 0
    end
  end

  describe "Genesis Testnet" do
    it "should have a correct hash" do
      BlockHeader.genesis_testnet.block_id.must_equal "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943"
      BlockHeader.genesis_testnet.height.must_equal 0
    end
  end
  
end