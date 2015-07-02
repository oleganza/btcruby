require_relative '../spec_helper'

describe BTC::IssuanceID do
  it "should encode script to a correct address" do
    key = Key.new(private_key: "18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725".from_hex, public_key_compressed: false)
    issuance_id = IssuanceID.new(outpoint: TransactionOutpoint.new(transaction_hash: BTC.hash256("tx1"), index:0), amount:100, network: Network.mainnet)
    issuance_id.hash.to_hex.must_equal "5e398b12cce30c0e1550e29f9d1b8f024772ac69"
    issuance_id.to_s.must_equal "SVtDV3pMkQQu11CQMzsziCmFBx4Ff5FnPT"
    issuance_id.is_a?(BTC::IssuanceID).must_equal true
  end
  it "should decode an asset address" do
    issuance_id = Address.parse("SVtDV3pMkQQu11CQMzsziCmFBx4Ff5FnPT")
    issuance_id.is_a?(BTC::IssuanceID).must_equal true
    issuance_id.hash.to_hex.must_equal "5e398b12cce30c0e1550e29f9d1b8f024772ac69"
  end
end
