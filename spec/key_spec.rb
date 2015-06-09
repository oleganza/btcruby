require_relative 'spec_helper'

describe BTC::Key do

  def verify_rfc6979_nonce(keyhex, msg, khex)
    keybin = BTC.from_hex(keyhex)
    hash = BTC.sha256(msg)
    k = BTC::OpenSSL.rfc6979_ecdsa_nonce(hash, keybin)
    k.to_hex.must_equal khex
  end

  def verify_rfc6979_signature(keyhex, msg, sighex)
    key = BTC::Key.new(private_key: keyhex.from_hex)
    hash = BTC.sha256(msg)
    sig = key.ecdsa_signature(hash)
    sig.to_hex.must_equal sighex
  end

  it "should use deterministic ECDSA nonce according to RFC6979" do
    verify_rfc6979_nonce("cca9fbcc1b41e5a95d369eaa6ddcff73b61a4efaa279cfc6567e8daa39cbaf50",
                         "sample",
                         "2df40ca70e639d89528a6b670d9d48d9165fdc0febc0974056bdce192b8e16a3")
    verify_rfc6979_nonce("0000000000000000000000000000000000000000000000000000000000000001",
                         "Satoshi Nakamoto",
                         "8f8a276c19f4149656b280621e358cce24f5f52542772691ee69063b74f15d15")
    verify_rfc6979_nonce("fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140",
                         "Satoshi Nakamoto",
                         "33a19b60e25fb6f4435af53a3d42d493644827367e6453928554f43e49aa6f90")
    verify_rfc6979_nonce("f8b8af8ce3c7cca5e300d33939540c10d45ce001b8f252bfbc57ba0342904181",
                         "Alan Turing",
                         "525a82b70e67874398067543fd84c83d30c175fdc45fdeee082fe13b1d7cfdf1")
    verify_rfc6979_nonce("0000000000000000000000000000000000000000000000000000000000000001",
                         "All those moments will be lost in time, like tears in rain. Time to die...",
                         "38aa22d72376b4dbc472e06c3ba403ee0a394da63fc58d88686c611aba98d6b3")
    verify_rfc6979_nonce("e91671c46231f833a6406ccbea0e3e392c76c167bac1cb013f6f1013980455c2",
                         "There is a computer disease that anybody who works with computers knows about. It's a very serious disease and it interferes completely with the work. The trouble with computers is that you 'play' with them!",
                         "1f4b84c23a86a221d233f2521be018d9318639d5b8bbd6374a8a59232d16ad3d")
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

  it "should perform Diffie-Hellman multiplication" do
    alice = BTC::Key.new(private_key: "c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a".from_hex, public_key_compressed: true)
    bob = BTC::Key.new(private_key: "2db963f0fe106f483d9afa73bd4e39a8ac4bbcb1fbec99d65bf59d85c8cb62ee".from_hex, public_key_compressed: true)
    dh_pubkey1 = alice.diffie_hellman(bob)
    dh_pubkey1.compressed_public_key.to_hex.must_equal "03735932754bc16e10febe40ee0280906d29459d477442f1838dcf27de3b5d9699"

    dh_pubkey2 = bob.diffie_hellman(alice)
    dh_pubkey2.compressed_public_key.to_hex.must_equal "03735932754bc16e10febe40ee0280906d29459d477442f1838dcf27de3b5d9699"
  end

  it "should support compressed public keys" do
    k = BTC::Key.new(private_key: "c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a".from_hex, public_key_compressed: true)
    k.private_key.to_hex.must_equal "c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a"
    k.public_key.to_hex.must_equal "0378d430274f8c5ec1321338151e9f27f4c676a008bdf8638d07c0b6be9ab35c71"
    k.address.to_s.must_equal "1C7zdTfnkzmr13HfA2vNm5SJYRK6nEKyq8"
    k.public_key_compressed.must_equal true

    k.compressed_public_key.to_hex.must_equal "0378d430274f8c5ec1321338151e9f27f4c676a008bdf8638d07c0b6be9ab35c71"
    k.uncompressed_public_key.to_hex.must_equal "0478d430274f8c5ec1321338151e9f27f4c676a008bdf8638d07c0b6be9ab35c71a1518063243acd4dfe96b66e3f2ec8013c8e072cd09b3834a19f81f659cc3455"

    (k.compressed_key == k).must_equal true
    (k.uncompressed_key == k).must_equal false

    k.compressed_key.address.to_s.must_equal "1C7zdTfnkzmr13HfA2vNm5SJYRK6nEKyq8"
    k.uncompressed_key.address.to_s.must_equal "1JwSSubhmg6iPtRjtyqhUYYH7bZg3Lfy1T"
  end

  it "should support uncompressed public keys" do
    k = BTC::Key.new(private_key: BTC.from_hex("c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a"), public_key_compressed: false)
    k.private_key.to_hex.must_equal "c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a"
    k.public_key.to_hex.must_equal "0478d430274f8c5ec1321338151e9f27f4c676a008bdf8638d07c0b6be9ab35c71a1518063243acd4dfe96b66e3f2ec8013c8e072cd09b3834a19f81f659cc3455"
    k.address.to_s.must_equal "1JwSSubhmg6iPtRjtyqhUYYH7bZg3Lfy1T"
    k.public_key_compressed.must_equal false

    k.compressed_public_key.to_hex.must_equal "0378d430274f8c5ec1321338151e9f27f4c676a008bdf8638d07c0b6be9ab35c71"
    k.uncompressed_public_key.to_hex.must_equal "0478d430274f8c5ec1321338151e9f27f4c676a008bdf8638d07c0b6be9ab35c71a1518063243acd4dfe96b66e3f2ec8013c8e072cd09b3834a19f81f659cc3455"

    (k.compressed_key == k).must_equal false
    (k.uncompressed_key == k).must_equal true

    k.compressed_key.address.to_s.must_equal "1C7zdTfnkzmr13HfA2vNm5SJYRK6nEKyq8"
    k.uncompressed_key.address.to_s.must_equal "1JwSSubhmg6iPtRjtyqhUYYH7bZg3Lfy1T"
  end

  it "should sign and verify data using ECDSA signatures" do
    300.times do |n|
      message = "Test message #{n}"
      private_key = "Key #{n}".sha256

      key = BTC::Key.new(private_key: private_key)

      signature = key.ecdsa_signature(message.sha256)

      signature.bytesize.must_be :>=, 60
      signature.bytesize.must_be :<=, 72

      key2 = BTC::Key.new(public_key: key.public_key)

      result = key2.verify_ecdsa_signature(signature, message.sha256)
      result.must_equal true
    end
  end

  it "should test canonicality of the signature" do

    # Stress-test canonicality checks
    key = BTC::Key.new(private_key: BTC.sha256("some key"))
    2560.times do |i|
      hash = BTC.sha256("tx#{i}")
      sig = key.ecdsa_signature(hash) + "\x01".b
      canonical = Key.validate_script_signature(sig)
      if !canonical
        puts Diagnostics.current.last_message
      end
      canonical.must_equal true
    end

    sig = "3045022100e81a33ac22d0ef25d359a5353977f0f953608b2733141239ec02363237ab6781022045c71237e95b56079e9fa88591060e4c1a4bb02c0cad1ebeb092749d4aa9754701".from_hex
    canonical = Key.validate_script_signature(sig)
    if !canonical
      puts Diagnostics.current.last_message
    end
    canonical.must_equal true
  end

  it "should test normalization of non-canonical signatures" do

    # # Generate non-canonical signatures
    # key = BTC::Key.new(private_key: BTC.sha256("some other key"))
    # 2560.times do |i|
    #   hash = BTC.sha256("tx#{i}")
    #   sig = key.ecdsa_signature(hash, normalized: false) + "\x01".b
    #   if !Key.validate_script_signature(sig)
    #     puts sig[0, sig.size - 1].to_hex
    #   end
    # end
    %w[
      30460221009bf6f0f7480d0562f5f56bc53bc90d564d7ce15ecbd116716c583da7311098b8022100880fd3e1c788c144aeede40072e814bead8b470a5a7f978a3804363b4920dc37
      304502206700757f4609501016944a7b3144fee587848ad108c79dd4eb7664ac374d646c022100b762e1010f4300fb3b15cde575c80ad405314472812051e34823a5051bfc13fe
      3046022100e71c70039b4f3c3894a3e5d20d1e19f95fc7b216a3ad2f540bd817470c07530e022100ebacde4827011195bd789edb6e3bca4dd0d5b59cae6892ee88465ebb205674b3
      3045022000ef0203c4df709ab28f701a6c340ecce0c30d60b717096c7a360d4a801371fe022100cd83e86d6d5f0304d8ef428ed928a5af3fcfec652fb334bbfb9e2750c8ebb51a
      3046022100cda613be5da7afc13aa6e04399557603b10317ca09e53a8d24c4ea0d892a0a9702210081a3012d810d6228c532fc8225dc32babda8f7b7f749c656b84af14e41a50ef2
      3045022063ec43b0a6515abe17636058aac61b11b2e11becbb49439b711cb868788fe52e022100ed350ebafa430efc8e55285aa94ee8365345238596412ac085f9fc0898bb0003
      3046022100d4890791c4b9f9fc7a9e853da404df26ab2302c5046527faaf9ae9fd8c99213a022100daec31bda7aa8ce0d9459e14d9fe86feda806ff90b6dd9701a6d94fad04a2860
      304502203ee680db8f247e005e84bb0db8e0a39bf47d32282c730b0f1b003c1f32891730022100d69b240494d0562de75b3916acc023711cc37c30d70760ab1fc35e8931738410
      304502206f08b37b53fd27096161015c53e20e05e01af59a32333e2bb79fb629479bd3800221009b125d988cd210c2438e6a206f5b9ddd7b6eae67accb0b914fde6b2a80c39b21
      3046022100bf94dadbff4a67716955fcc4e22c3c4c88852ef31c5a0c1145ad3d433c97705d022100f2c339e6a1cc6ce75fda29b9d47dc2e7f6fb1df4a2f5e8502a75faf63f2cc87b
      3046022100cf268bfa6c9b0a10747979654e386fb64d18bd2ae69e549a0545dc2fe154a6cb022100f651c4389233482f8b99f39f2e2d1fd29c08795f0dad50de47860bca29a4300d
      304502203a969e1650b758a6597c01beb050ae737838c24376fcf0cf8fb66b2bb1b291a7022100b59ba04b19a00becb4e41e964cec1c29fd5d080be53d844b020d613a71ae7f65
      304602210085234fe98f3bb43e665b2d138de16a265751b83851b1fc50478359c731b9a185022100db2a37784987554344071e60df361d847e1ee2c18844321a7a1edb9a0b53cd92
      3046022100b07a37a66c5db8c718147d16b74fbba048e632911be0db380821c399e4823702022100ff67919de148346fdb4d25676d4c4e42a5002002c9c7e20176783ceb46e08a02
      3046022100a962f13335383fa0a2ad2c38568fe87301dcc7b8e78cafc05dc3e805c0ecb02b022100c15a38847cc259b0f616cb477ecde0ea0fe8767f0aac1e630e314fcde4c65487
      3046022100a8ba33f415f456c7f8daac01824a17612927c4c2b35876caf26b63e33fa17b99022100b4e89ea2021afd554f5f048cc5b9208bba55e727133ca184b51de121654efb33
      3045022079b58a6574851d07ab8779a6a6597c326f9181852f88156546ce2331f95bc5b2022100dea5a3b8f454a781e444854416b2a42bacc02d1d21ad385022f50b439c98c076
      304502201ff1e2b23342bc5d2960822247084fb86e4be9a37bb0a6a9aad512b6627c2e0a0221008624ceebb150e1de1103b51e1ac533f43e8e7322a37c925baae0dcc90e272ea2
      304502205ee578855612719d0f4a7bcaf149d5f283a12176e99a27042d9d8f4a9074f2dd022100f4d7b7b923de4d63e646bb6890ef3634bc317c6dd04e55f2ffa686e32574ccb7
      3046022100c2e4f75fd6c294c03dd684608212ec65240bd3319abe20663c7a24676ad8ef600221008743b32fd6051c2eaf326f2e824d3a8ca0ebdc1aa25175ee6b61c1f694b9cfbd
      30450220450d1e68977e2ad2776925725e444eb9a58743459a4fd15188552cfc171f8798022100edac0b9210f02f0d8d4201729c8d62c7c302cb7c1a6f9f2f7741c7f99a3518a2
      3045022018cddb05aa87011d7fe3ba56d6657bd813eeab9c43e2422af2f44cdd3bd8bc3a022100c53eb96ba81e12e59da73846223310ea6cb325a42ab2a081a101d99c5e3bfeec
      304502200be9a279cca265b4e273c165d877474ab854b14ce2b17dff958dc932eae3d9e8022100e45c9087e78ff0120ae2f911299f64c995c61d6750a5913eaac36f096b560685
      3045022062d08bff9580238c8cd62d9d64e9c1d518932886651f46a445bff773993500f00221008029263cc9ec64589bbbe140995096c257a1fbacf5f9f5ee69a69b96c626cc7a
    ].each do |hex_sig|
      sig = hex_sig.from_hex
      canonical = Key.validate_script_signature(sig + "\x01".b)
      canonical.must_equal false
      sig2 = Key.normalized_signature(sig)
      sig2.wont_equal nil
      sig2.wont_equal sig
      canonical = Key.validate_script_signature(sig2 + "\x01".b)
      if !canonical
        puts Diagnostics.current.last_message
      end
      canonical.must_equal true

      # Non-canonical signature must be normalized
      sig3 = Key.validate_and_normalize_script_signature(sig + "\x01".b)
      sig3.must_equal sig2 + "\x01".b

      # Canonical signature should stay the same
      sig4 = Key.validate_and_normalize_script_signature(sig2 + "\x01".b)
      sig4.must_equal sig2 + "\x01".b
    end
  end

end
