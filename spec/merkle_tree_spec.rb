require_relative 'spec_helper'
describe BTC::MerkleTree do
  
  it "should compute root of one hash equal to that hash" do
    hash = "5df6e0e2761359d30a8275058e299fcc0381534545f55cf43e41983f5d4c9456"
    MerkleTree.new(hashes: [hash.from_hex]).merkle_root.to_hex.must_equal hash
  end

  it "merkle root of 2 hashes must equal hash(a+b)" do
    a = "9c2e4d8fe97d881430de4e754b4205b9c27ce96715231cffc4337340cb110280".from_hex
    b = "0c08173828583fc6ecd6ecdbcca7b6939c49c242ad5107e39deb7b0a5996b903".from_hex
    r = "7de236613dd3d9fa1d86054a84952f1e0df2f130546b394a4d4dd7b76997f607".from_hex
    r.to_hex.must_equal BTC.hash256(a+b).to_hex
    mt = MerkleTree.new(hashes: [a,b])
    mt.tail_duplicates?.must_equal false
    mt.merkle_root.to_hex.must_equal r.to_hex
  end

  it "merkle root of 3 hashes must equal Hash(Hash(a+b)+Hash(c+c))" do
    a = "9c2e4d8fe97d881430de4e754b4205b9c27ce96715231cffc4337340cb110280".from_hex
    b = "0c08173828583fc6ecd6ecdbcca7b6939c49c242ad5107e39deb7b0a5996b903".from_hex
    c = "80903da4e6bbdf96e8ff6fc3966b0cfd355c7e860bdd1caa8e4722d9230e40ac".from_hex
    r = "5b7534123197114fa7e7459075f39d89ffab74b5c3f31fad48a025b931ff5a01".from_hex
    r.to_hex.must_equal BTC.hash256(BTC.hash256(a+b)+BTC.hash256(c+c)).to_hex
    mt = MerkleTree.new(hashes: [a,b,c])
    mt.tail_duplicates?.must_equal false
    mt.merkle_root.to_hex.must_equal r.to_hex
  end

end
