require_relative 'spec_helper'
describe BTC::Script do

  it "should instantiate with empty data" do
    empty_script = Script.new
    empty_script.data.must_equal "".b
    empty_script.to_s.must_equal ''
  end

  it "should support standard P2PKH script" do
    script = (Script.new << OP_DUP << OP_HASH160 << "5a73e920b7836c74f9e740a5bb885e8580557038".from_hex << OP_EQUALVERIFY << OP_CHECKSIG)
    script.standard?.must_equal true
    script.public_key_hash_script?.must_equal true
    script.script_hash_script?.must_equal false
    script.multisig_script?.must_equal false
    script.standard_multisig_script?.must_equal false
    script.standard_address.class.must_equal PublicKeyAddress
    script.standard_address.data.must_equal "5a73e920b7836c74f9e740a5bb885e8580557038".from_hex
    script.to_s.must_equal "OP_DUP OP_HASH160 5a73e920b7836c74f9e740a5bb885e8580557038 OP_EQUALVERIFY OP_CHECKSIG"
  end

  it "should support standard P2SH script" do
    script = (Script.new << OP_HASH160 << "5a73e920b7836c74f9e740a5bb885e8580557038".from_hex << OP_EQUAL)
    script.standard?.must_equal true
    script.public_key_hash_script?.must_equal false
    script.script_hash_script?.must_equal true
    script.multisig_script?.must_equal false
    script.standard_multisig_script?.must_equal false
    script.standard_address.class.must_equal ScriptHashAddress
    script.standard_address.data.must_equal "5a73e920b7836c74f9e740a5bb885e8580557038".from_hex
    script.to_s.must_equal "OP_HASH160 5a73e920b7836c74f9e740a5bb885e8580557038 OP_EQUAL"
  end

  it "should support standard multisig script" do
    script = (Script.new << OP_1 <<
              "c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a".from_hex <<
              "bffbec99da8a6573bd4e359d85c8cb62e6f483d9afac4be2db963f0fe10bcb19".from_hex <<
              OP_2 <<
              OP_CHECKMULTISIG)
    script.standard?.must_equal true
    script.public_key_hash_script?.must_equal false
    script.script_hash_script?.must_equal false
    script.multisig_script?.must_equal true
    script.standard_multisig_script?.must_equal true
    script.standard_address.must_equal nil
    script.multisig_public_keys.must_equal [
      "c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a".from_hex,
      "bffbec99da8a6573bd4e359d85c8cb62e6f483d9afac4be2db963f0fe10bcb19".from_hex
    ]
    script.multisig_signatures_required.must_equal 1
    script.to_s.must_equal "OP_1 c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a "+
                           "bffbec99da8a6573bd4e359d85c8cb62e6f483d9afac4be2db963f0fe10bcb19 OP_2 OP_CHECKMULTISIG"

    script2 = Script.multisig(public_keys:[
                             "c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a".from_hex,
                             "bffbec99da8a6573bd4e359d85c8cb62e6f483d9afac4be2db963f0fe10bcb19".from_hex
                           ], signatures_required: 1)

    script2.standard_multisig_script?.must_equal true
    script.must_equal script2


  end


end
