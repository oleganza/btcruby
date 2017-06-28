require_relative 'spec_helper'
require_relative '../lib/btcruby/secp256k1'
describe BTC::Secp256k1 do
  
  def verify_rfc6979_signature(keyhex, msg, sighex)
    key = BTC::Key.new(private_key: keyhex.from_hex)
    hash = BTC.sha256(msg)
    sig = BTC::Secp256k1.ecdsa_signature(hash, key.private_key)
    sig.to_hex.must_equal sighex
  end

  it "should produce deterministic ECDSA signatures Bitcoin-canonical using nonce from RFC6979" do
    verify_rfc6979_signature("cca9fbcc1b41e5a95d369eaa6ddcff73b61a4efaa279cfc6567e8daa39cbaf50",
                             "sample",
                             "3045022100af340daf02cc15c8d5d08d7735dfe6b98a474ed373bdb5fbecf7571be52b384202205009fb27f37034a9b24b707b7c6b79ca23ddef9e25f7282e8a797efe53a8f124")
    verify_rfc6979_signature("0000000000000000000000000000000000000000000000000000000000000001",
                             "Satoshi Nakamoto",
                             "3045022100934b1ea10a4b3c1757e2b0c017d0b6143ce3c9a7e6a4a49860d7a6ab210ee3d802202442ce9d2b916064108014783e923ec36b49743e2ffa1c4496f01a512aafd9e5")
    verify_rfc6979_signature("fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140",
                             "Satoshi Nakamoto",
                             "3045022100fd567d121db66e382991534ada77a6bd3106f0a1098c231e47993447cd6af2d002206b39cd0eb1bc8603e159ef5c20a5c8ad685a45b06ce9bebed3f153d10d93bed5")
    verify_rfc6979_signature("f8b8af8ce3c7cca5e300d33939540c10d45ce001b8f252bfbc57ba0342904181",
                             "Alan Turing",
                             "304402207063ae83e7f62bbb171798131b4a0564b956930092b33b07b395615d9ec7e15c022058dfcc1e00a35e1572f366ffe34ba0fc47db1e7189759b9fb233c5b05ab388ea")
    verify_rfc6979_signature("0000000000000000000000000000000000000000000000000000000000000001",
                             "All those moments will be lost in time, like tears in rain. Time to die...",
                             "30450221008600dbd41e348fe5c9465ab92d23e3db8b98b873beecd930736488696438cb6b0220547fe64427496db33bf66019dacbf0039c04199abb0122918601db38a72cfc21")
    verify_rfc6979_signature("e91671c46231f833a6406ccbea0e3e392c76c167bac1cb013f6f1013980455c2",
                             "There is a computer disease that anybody who works with computers knows about. It's a very serious disease and it interferes completely with the work. The trouble with computers is that you 'play' with them!",
                             "3045022100b552edd27580141f3b2a5463048cb7cd3e047b97c9f98076c32dbdf85a68718b0220279fa72dd19bfae05577e06c7c0c1900c371fcd5893f7e1d56a37d30174671f6")
  end

end
