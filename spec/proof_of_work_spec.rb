require_relative 'spec_helper'
describe BTC::ProofOfWork do

  POW = BTC::ProofOfWork

  it "should convert target to bits" do
    POW.bits_from_target(0x00000000ffff0000000000000000000000000000000000000000000000000000).must_equal 0x1d00ffff
    POW.bits_from_target(0x00000007fff80000000000000000000000000000000000000000000000000000).must_equal 0x1d07fff8
    POW.bits_from_target(0x0).must_equal 0x03000000
  end

  it "should convert bits to target" do
    POW.target_from_bits(0x1d00ffff).must_equal 0x00000000ffff0000000000000000000000000000000000000000000000000000
    POW.target_from_bits(0x1d07fff8).must_equal 0x00000007fff80000000000000000000000000000000000000000000000000000
    POW.target_from_bits(0x03000000).must_equal 0x0
  end

  it "should convert hash to target integer" do
    POW.target_from_hash("").must_equal 0
    POW.target_from_hash("\x00").must_equal 0
    POW.target_from_hash("\x12").must_equal 0x12
    POW.target_from_hash("6fe28c0ab6f1b372c1a6a246ae63f74f931e8365e15a089c68d6190000000000".from_hex).must_equal 0x000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f
  end

  it "should convert target integer to 32-byte hash" do
    POW.hash_from_target(0).must_equal "\x00"*32
    POW.hash_from_target(0xbabe).must_equal "\xbe\xba".b.ljust(32, "\x00")
    POW.hash_from_target(0x000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f).must_equal "6fe28c0ab6f1b372c1a6a246ae63f74f931e8365e15a089c68d6190000000000".from_hex
  end

  it "should convert target to difficulty (on mainnet)" do
    POW.difficulty_from_target(0x00000000ffff0000000000000000000000000000000000000000000000000000).to_i.must_equal 1
    POW.difficulty_from_target(0x000000007fff8000000000000000000000000000000000000000000000000000).to_i.must_equal 2
    POW.difficulty_from_target(0x000000000ffff000000000000000000000000000000000000000000000000000).to_i.must_equal 16
    POW.difficulty_from_target(0x0000000000ffff00000000000000000000000000000000000000000000000000).to_i.must_equal 256
  end

  it "should convert target to difficulty (on testnet)" do
    POW.difficulty_from_target(0x00000007fff80000000000000000000000000000000000000000000000000000,
                                                max_target: POW::MAX_TARGET_TESTNET).to_i.must_equal 1
    POW.difficulty_from_target(0x00000003fff80000000000000000000000000000000000000000000000000000,
                                                max_target: POW::MAX_TARGET_TESTNET).to_i.must_equal 2
    POW.difficulty_from_target(0x000000007fff8000000000000000000000000000000000000000000000000000,
                                                max_target: POW::MAX_TARGET_TESTNET).to_i.must_equal 16
    POW.difficulty_from_target(0x0000000007fff800000000000000000000000000000000000000000000000000,
                                                max_target: POW::MAX_TARGET_TESTNET).to_i.must_equal 256
  end
  
  it "should convert difficulty to target or bits" do
    POW.target_from_difficulty(1.0).must_equal 0x00000000ffff0000000000000000000000000000000000000000000000000000
    POW.bits_from_difficulty(39603666252.41841).must_equal 0x181bc330
  end
end
