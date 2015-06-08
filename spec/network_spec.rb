require_relative 'spec_helper'

describe BTC::Network do

  it "should have mainnet shared instance" do
    mainnet = BTC::Network.mainnet
    mainnet.name.must_equal "mainnet"
    mainnet.mainnet?.must_equal true
    mainnet.mainnet.must_equal true
    mainnet.testnet?.must_equal false
    mainnet.testnet.must_equal false
    mainnet.genesis_block.block_id.must_equal "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f"
    mainnet.genesis_block_header.block_id.must_equal "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f"
    mainnet.max_target.must_equal 0x00000000ffff0000000000000000000000000000000000000000000000000000
    BTC::Network.mainnet.object_id.must_equal BTC::Network.mainnet.object_id
  end

  it "should have testnet shared instance" do
    testnet = BTC::Network.testnet
    testnet.name.must_equal "testnet3"
    testnet.mainnet?.must_equal false
    testnet.mainnet.must_equal false
    testnet.testnet?.must_equal true
    testnet.testnet.must_equal true
    testnet.genesis_block.block_id.must_equal "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943"
    testnet.genesis_block_header.block_id.must_equal "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943"
    testnet.max_target.must_equal 0x00000007fff80000000000000000000000000000000000000000000000000000
    BTC::Network.testnet.object_id.must_equal BTC::Network.testnet.object_id
  end
  
  it "should allow copying" do
    network = BTC::Network.testnet.dup
    network.object_id.wont_equal BTC::Network.testnet.object_id
    
    network.name.must_equal "testnet3"
    network.mainnet?.must_equal false
    network.testnet?.must_equal true
    
    network.name = "xnetwork"
    network.mainnet = true
    network.mainnet?.must_equal true
    network.testnet?.must_equal false
    
    BTC::Network.testnet.mainnet?.must_equal false
    BTC::Network.testnet.testnet?.must_equal true
  end

end
