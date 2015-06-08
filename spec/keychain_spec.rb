require_relative 'spec_helper'

describe BTC::Keychain do

  it "should support tpub/tprv prefixes for testnet" do
    seed = "000102030405060708090a0b0c0d0e0f".from_hex
    master = Keychain.new(seed: seed)
    master.network = Network.testnet
    master.xpub.must_equal "tpubD6NzVbkrYhZ4XgiXtGrdW5XDAPFCL9h7we1vwNCpn8tGbBcgfVYjXyhWo4E1xkh56hjod1RhGjxbaTLV3X4FyWuejifB9jusQ46QzG87VKp"
    master.xprv.must_equal "tprv8ZgxMBicQKsPeDgjzdC36fs6bMjGApWDNLR9erAXMs5skhMv36j9MV5ecvfavji5khqjWaWSFhN3YcCUUdiKH6isR4Pwy3U5y5egddBr16m"
    master.network = Network.mainnet
    master.xpub.must_equal "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8"
    master.xprv.must_equal "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi"
  end

  it "should support path API" do
    seed = "000102030405060708090a0b0c0d0e0f".from_hex
    master = Keychain.new(seed: seed)
    master.derived_keychain("").xpub.must_equal       "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8"
    master.derived_keychain("m").xpub.must_equal      "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8"
    master.derived_keychain("0'").xpub.must_equal     "xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw"
    master.derived_keychain("m/0'").xpub.must_equal   "xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw"
    master.derived_keychain("0'").xpub.must_equal     "xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw"
    master.derived_keychain("m/0'/1").xpub.must_equal "xpub6ASuArnXKPbfEwhqN6e3mwBcDTgzisQN1wXN9BJcM47sSikHjJf3UFHKkNAWbWMiGj7Wf5uMash7SyYq527Hqck2AxYysAA7xmALppuCkwQ"
    master.derived_keychain("0'/1").xpub.must_equal   "xpub6ASuArnXKPbfEwhqN6e3mwBcDTgzisQN1wXN9BJcM47sSikHjJf3UFHKkNAWbWMiGj7Wf5uMash7SyYq527Hqck2AxYysAA7xmALppuCkwQ"
    master.derived_keychain("m/0'/1/2'").xprv.must_equal "xprv9z4pot5VBttmtdRTWfWQmoH1taj2axGVzFqSb8C9xaxKymcFzXBDptWmT7FwuEzG3ryjH4ktypQSAewRiNMjANTtpgP4mLTj34bhnZX7UiM"
    master.derived_keychain("0'/1/2'").xprv.must_equal   "xprv9z4pot5VBttmtdRTWfWQmoH1taj2axGVzFqSb8C9xaxKymcFzXBDptWmT7FwuEzG3ryjH4ktypQSAewRiNMjANTtpgP4mLTj34bhnZX7UiM"
    master.derived_keychain("m/0'/1/2'/2/1000000000").xpub.must_equal "xpub6H1LXWLaKsWFhvm6RVpEL9P4KfRZSW7abD2ttkWP3SSQvnyA8FSVqNTEcYFgJS2UaFcxupHiYkro49S8yGasTvXEYBVPamhGW6cFJodrTHy"
    master.derived_keychain("0'/1/2'/2/1000000000").xprv.must_equal   "xprvA41z7zogVVwxVSgdKUHDy1SKmdb533PjDz7J6N6mV6uS3ze1ai8FHa8kmHScGpWmj4WggLyQjgPie1rFSruoUihUZREPSL39UNdE3BBDu76"
  end

  it "should support test vector 1" do
    # Master (hex): 000102030405060708090a0b0c0d0e0f
    # * [Chain m]
    # * ext pub: xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8
    # * ext prv: xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi
    # * [Chain m/0']
    # * ext pub: xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw
    # * ext prv: xprv9uHRZZhk6KAJC1avXpDAp4MDc3sQKNxDiPvvkX8Br5ngLNv1TxvUxt4cV1rGL5hj6KCesnDYUhd7oWgT11eZG7XnxHrnYeSvkzY7d2bhkJ7
    # * [Chain m/0'/1]
    # * ext pub: xpub6ASuArnXKPbfEwhqN6e3mwBcDTgzisQN1wXN9BJcM47sSikHjJf3UFHKkNAWbWMiGj7Wf5uMash7SyYq527Hqck2AxYysAA7xmALppuCkwQ
    # * ext prv: xprv9wTYmMFdV23N2TdNG573QoEsfRrWKQgWeibmLntzniatZvR9BmLnvSxqu53Kw1UmYPxLgboyZQaXwTCg8MSY3H2EU4pWcQDnRnrVA1xe8fs
    # * [Chain m/0'/1/2']
    # * ext pub: xpub6D4BDPcP2GT577Vvch3R8wDkScZWzQzMMUm3PWbmWvVJrZwQY4VUNgqFJPMM3No2dFDFGTsxxpG5uJh7n7epu4trkrX7x7DogT5Uv6fcLW5
    # * ext prv: xprv9z4pot5VBttmtdRTWfWQmoH1taj2axGVzFqSb8C9xaxKymcFzXBDptWmT7FwuEzG3ryjH4ktypQSAewRiNMjANTtpgP4mLTj34bhnZX7UiM
    # * [Chain m/0'/1/2'/2]
    # * ext pub: xpub6FHa3pjLCk84BayeJxFW2SP4XRrFd1JYnxeLeU8EqN3vDfZmbqBqaGJAyiLjTAwm6ZLRQUMv1ZACTj37sR62cfN7fe5JnJ7dh8zL4fiyLHV
    # * ext prv: xprvA2JDeKCSNNZky6uBCviVfJSKyQ1mDYahRjijr5idH2WwLsEd4Hsb2Tyh8RfQMuPh7f7RtyzTtdrbdqqsunu5Mm3wDvUAKRHSC34sJ7in334
    # * [Chain m/0'/1/2'/2/1000000000]
    # * ext pub: xpub6H1LXWLaKsWFhvm6RVpEL9P4KfRZSW7abD2ttkWP3SSQvnyA8FSVqNTEcYFgJS2UaFcxupHiYkro49S8yGasTvXEYBVPamhGW6cFJodrTHy
    # * ext prv: xprvA41z7zogVVwxVSgdKUHDy1SKmdb533PjDz7J6N6mV6uS3ze1ai8FHa8kmHScGpWmj4WggLyQjgPie1rFSruoUihUZREPSL39UNdE3BBDu76

    seed = "000102030405060708090a0b0c0d0e0f".from_hex
    master = Keychain.new(seed: seed)

    master.key.address.to_s.must_equal "15mKKb2eos1hWa6tisdPwwDC1a5J1y9nma"
    master.key.address.to_s.must_equal master.public_keychain.key.address.to_s

    master.parent_fingerprint.must_equal 0
    master.identifier.to_hex.must_equal "3442193e1bb70916e914552172cd4e2dbc9df811"
    master.fingerprint.must_equal 876747070
    master.depth.must_equal 0
    master.index.must_equal 0
    master.hardened?.must_equal false
    master.mainnet?.must_equal true
    master.testnet?.must_equal false
    master.private?.must_equal true
    master.hardened?.must_equal false

    master.xpub.must_equal "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8"
    master.xprv.must_equal "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi"

    master2 = Keychain.new(xprv: master.extended_private_key)
    master2.private?.must_equal true
    (master2 == master).must_equal true
    master2.xpub.must_equal master.xpub
    master2.xprv.must_equal master.xprv

    m0prv = master.derived_keychain(0, hardened:true)

    m0prv.parent_fingerprint.wont_equal 0
    m0prv.depth.must_equal 1
    m0prv.index.must_equal 0
    m0prv.private?.must_equal true
    m0prv.hardened?.must_equal true

    m0prv.extended_public_key.must_equal  "xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw"
    m0prv.extended_private_key.must_equal "xprv9uHRZZhk6KAJC1avXpDAp4MDc3sQKNxDiPvvkX8Br5ngLNv1TxvUxt4cV1rGL5hj6KCesnDYUhd7oWgT11eZG7XnxHrnYeSvkzY7d2bhkJ7"

    m0prv1pub = m0prv.derived_keychain(1)

    m0prv1pub.parent_fingerprint.wont_equal 0
    m0prv1pub.depth.must_equal 2
    m0prv1pub.index.must_equal 1
    m0prv1pub.private?.must_equal true
    m0prv1pub.hardened?.must_equal false

    m0prv1pub.extended_public_key.must_equal "xpub6ASuArnXKPbfEwhqN6e3mwBcDTgzisQN1wXN9BJcM47sSikHjJf3UFHKkNAWbWMiGj7Wf5uMash7SyYq527Hqck2AxYysAA7xmALppuCkwQ"
    m0prv1pub.extended_private_key.must_equal "xprv9wTYmMFdV23N2TdNG573QoEsfRrWKQgWeibmLntzniatZvR9BmLnvSxqu53Kw1UmYPxLgboyZQaXwTCg8MSY3H2EU4pWcQDnRnrVA1xe8fs"

    m0prv1pub2prv = m0prv1pub.derived_keychain(2, hardened:true)
    m0prv1pub2prv.extended_public_key.must_equal "xpub6D4BDPcP2GT577Vvch3R8wDkScZWzQzMMUm3PWbmWvVJrZwQY4VUNgqFJPMM3No2dFDFGTsxxpG5uJh7n7epu4trkrX7x7DogT5Uv6fcLW5"
    m0prv1pub2prv.extended_private_key.must_equal "xprv9z4pot5VBttmtdRTWfWQmoH1taj2axGVzFqSb8C9xaxKymcFzXBDptWmT7FwuEzG3ryjH4ktypQSAewRiNMjANTtpgP4mLTj34bhnZX7UiM"

    m0prv1pub2prv2pub = m0prv1pub2prv.derived_keychain(2)
    m0prv1pub2prv2pub.extended_public_key.must_equal "xpub6FHa3pjLCk84BayeJxFW2SP4XRrFd1JYnxeLeU8EqN3vDfZmbqBqaGJAyiLjTAwm6ZLRQUMv1ZACTj37sR62cfN7fe5JnJ7dh8zL4fiyLHV"
    m0prv1pub2prv2pub.extended_private_key.must_equal "xprvA2JDeKCSNNZky6uBCviVfJSKyQ1mDYahRjijr5idH2WwLsEd4Hsb2Tyh8RfQMuPh7f7RtyzTtdrbdqqsunu5Mm3wDvUAKRHSC34sJ7in334"

    m0prv1pub2prv2pub1Gpub = m0prv1pub2prv2pub.derived_keychain(1000000000)
    m0prv1pub2prv2pub1Gpub.extended_public_key.must_equal "xpub6H1LXWLaKsWFhvm6RVpEL9P4KfRZSW7abD2ttkWP3SSQvnyA8FSVqNTEcYFgJS2UaFcxupHiYkro49S8yGasTvXEYBVPamhGW6cFJodrTHy"
    m0prv1pub2prv2pub1Gpub.extended_private_key.must_equal "xprvA41z7zogVVwxVSgdKUHDy1SKmdb533PjDz7J6N6mV6uS3ze1ai8FHa8kmHScGpWmj4WggLyQjgPie1rFSruoUihUZREPSL39UNdE3BBDu76"


  end

  it "should support test vector 2" do
    # Master (hex): fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542
    # * [Chain m]
    # * ext pub: xpub661MyMwAqRbcFW31YEwpkMuc5THy2PSt5bDMsktWQcFF8syAmRUapSCGu8ED9W6oDMSgv6Zz8idoc4a6mr8BDzTJY47LJhkJ8UB7WEGuduB
    # * ext prv: xprv9s21ZrQH143K31xYSDQpPDxsXRTUcvj2iNHm5NUtrGiGG5e2DtALGdso3pGz6ssrdK4PFmM8NSpSBHNqPqm55Qn3LqFtT2emdEXVYsCzC2U
    # * [Chain m/0]
    # * ext pub: xpub69H7F5d8KSRgmmdJg2KhpAK8SR3DjMwAdkxj3ZuxV27CprR9LgpeyGmXUbC6wb7ERfvrnKZjXoUmmDznezpbZb7ap6r1D3tgFxHmwMkQTPH
    # * ext prv: xprv9vHkqa6EV4sPZHYqZznhT2NPtPCjKuDKGY38FBWLvgaDx45zo9WQRUT3dKYnjwih2yJD9mkrocEZXo1ex8G81dwSM1fwqWpWkeS3v86pgKt
    # * [Chain m/0/2147483647']
    # * ext pub: xpub6ASAVgeehLbnwdqV6UKMHVzgqAG8Gr6riv3Fxxpj8ksbH9ebxaEyBLZ85ySDhKiLDBrQSARLq1uNRts8RuJiHjaDMBU4Zn9h8LZNnBC5y4a
    # * ext prv: xprv9wSp6B7kry3Vj9m1zSnLvN3xH8RdsPP1Mh7fAaR7aRLcQMKTR2vidYEeEg2mUCTAwCd6vnxVrcjfy2kRgVsFawNzmjuHc2YmYRmagcEPdU9
    # * [Chain m/0/2147483647'/1]
    # * ext pub: xpub6DF8uhdarytz3FWdA8TvFSvvAh8dP3283MY7p2V4SeE2wyWmG5mg5EwVvmdMVCQcoNJxGoWaU9DCWh89LojfZ537wTfunKau47EL2dhHKon
    # * ext prv: xprv9zFnWC6h2cLgpmSA46vutJzBcfJ8yaJGg8cX1e5StJh45BBciYTRXSd25UEPVuesF9yog62tGAQtHjXajPPdbRCHuWS6T8XA2ECKADdw4Ef
    # * [Chain m/0/2147483647'/1/2147483646']
    # * ext pub: xpub6ERApfZwUNrhLCkDtcHTcxd75RbzS1ed54G1LkBUHQVHQKqhMkhgbmJbZRkrgZw4koxb5JaHWkY4ALHY2grBGRjaDMzQLcgJvLJuZZvRcEL
    # * ext prv: xprvA1RpRA33e1JQ7ifknakTFpgNXPmW2YvmhqLQYMmrj4xJXXWYpDPS3xz7iAxn8L39njGVyuoseXzU6rcxFLJ8HFsTjSyQbLYnMpCqE2VbFWc
    # * [Chain m/0/2147483647'/1/2147483646'/2]
    # * ext pub: xpub6FnCn6nSzZAw5Tw7cgR9bi15UV96gLZhjDstkXXxvCLsUXBGXPdSnLFbdpq8p9HmGsApME5hQTZ3emM2rnY5agb9rXpVGyy3bdW6EEgAtqt
    # * ext prv: xprvA2nrNbFZABcdryreWet9Ea4LvTJcGsqrMzxHx98MMrotbir7yrKCEXw7nadnHM8Dq38EGfSh6dqA9QWTyefMLEcBYJUuekgW4BYPJcr9E7j

    seed = "fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542".from_hex
    master = Keychain.new(seed: seed)

    master.parent_fingerprint.must_equal 0
    master.identifier.to_hex.must_equal "bd16bee53961a47d6ad888e29545434a89bdfe95"
    master.fingerprint.must_equal 3172384485
    master.depth.must_equal 0
    master.index.must_equal 0
    master.hardened?.must_equal false
    master.mainnet?.must_equal true
    master.testnet?.must_equal false
    master.private?.must_equal true
    master.hardened?.must_equal false

    master.extended_public_key.must_equal "xpub661MyMwAqRbcFW31YEwpkMuc5THy2PSt5bDMsktWQcFF8syAmRUapSCGu8ED9W6oDMSgv6Zz8idoc4a6mr8BDzTJY47LJhkJ8UB7WEGuduB"
    master.extended_private_key.must_equal "xprv9s21ZrQH143K31xYSDQpPDxsXRTUcvj2iNHm5NUtrGiGG5e2DtALGdso3pGz6ssrdK4PFmM8NSpSBHNqPqm55Qn3LqFtT2emdEXVYsCzC2U"

    m0pub = master.derived_keychain(0)
    m0pub.extended_public_key.must_equal "xpub69H7F5d8KSRgmmdJg2KhpAK8SR3DjMwAdkxj3ZuxV27CprR9LgpeyGmXUbC6wb7ERfvrnKZjXoUmmDznezpbZb7ap6r1D3tgFxHmwMkQTPH"
    m0pub.extended_private_key.must_equal "xprv9vHkqa6EV4sPZHYqZznhT2NPtPCjKuDKGY38FBWLvgaDx45zo9WQRUT3dKYnjwih2yJD9mkrocEZXo1ex8G81dwSM1fwqWpWkeS3v86pgKt"

    m0pubFFprv = m0pub.derived_keychain(2147483647, hardened:true)
    m0pubFFprv.extended_public_key.must_equal "xpub6ASAVgeehLbnwdqV6UKMHVzgqAG8Gr6riv3Fxxpj8ksbH9ebxaEyBLZ85ySDhKiLDBrQSARLq1uNRts8RuJiHjaDMBU4Zn9h8LZNnBC5y4a"
    m0pubFFprv.extended_private_key.must_equal "xprv9wSp6B7kry3Vj9m1zSnLvN3xH8RdsPP1Mh7fAaR7aRLcQMKTR2vidYEeEg2mUCTAwCd6vnxVrcjfy2kRgVsFawNzmjuHc2YmYRmagcEPdU9"

    m0pubFFprv1 = m0pubFFprv.derived_keychain(1)
    m0pubFFprv1.extended_public_key.must_equal "xpub6DF8uhdarytz3FWdA8TvFSvvAh8dP3283MY7p2V4SeE2wyWmG5mg5EwVvmdMVCQcoNJxGoWaU9DCWh89LojfZ537wTfunKau47EL2dhHKon"
    m0pubFFprv1.extended_private_key.must_equal "xprv9zFnWC6h2cLgpmSA46vutJzBcfJ8yaJGg8cX1e5StJh45BBciYTRXSd25UEPVuesF9yog62tGAQtHjXajPPdbRCHuWS6T8XA2ECKADdw4Ef"

    m0pubFFprv1pubFEprv = m0pubFFprv1.derived_keychain(2147483646, hardened:true)
    m0pubFFprv1pubFEprv.extended_public_key.must_equal "xpub6ERApfZwUNrhLCkDtcHTcxd75RbzS1ed54G1LkBUHQVHQKqhMkhgbmJbZRkrgZw4koxb5JaHWkY4ALHY2grBGRjaDMzQLcgJvLJuZZvRcEL"
    m0pubFFprv1pubFEprv.extended_private_key.must_equal "xprvA1RpRA33e1JQ7ifknakTFpgNXPmW2YvmhqLQYMmrj4xJXXWYpDPS3xz7iAxn8L39njGVyuoseXzU6rcxFLJ8HFsTjSyQbLYnMpCqE2VbFWc"

    m0pubFFprv1pubFEprv2 = m0pubFFprv1pubFEprv.derived_keychain(2)
    m0pubFFprv1pubFEprv2.extended_public_key.must_equal "xpub6FnCn6nSzZAw5Tw7cgR9bi15UV96gLZhjDstkXXxvCLsUXBGXPdSnLFbdpq8p9HmGsApME5hQTZ3emM2rnY5agb9rXpVGyy3bdW6EEgAtqt"
    m0pubFFprv1pubFEprv2.extended_private_key.must_equal "xprvA2nrNbFZABcdryreWet9Ea4LvTJcGsqrMzxHx98MMrotbir7yrKCEXw7nadnHM8Dq38EGfSh6dqA9QWTyefMLEcBYJUuekgW4BYPJcr9E7j"
  end

  it "should behave correctly on privkeys below 32-byte size" do
    keychain = Keychain.new(seed: "stress test")
    #puts keychain.extended_private_key
    # Uncomment this to figure out the indexes for the shorter keys
    if false
      indexes = []
      10000.times do |i|
        key = keychain.derived_key(i, hardened: true)
        key.private_key.bytesize.must_equal 32
        key.public_key.bytesize.must_equal 33
        if key.private_key.bytes[0] == 0
          indexes << i
          puts "i = #{i}  " + key.private_key.to_hex + "  #{key.address.to_s}"
        end
      end      
      puts "Short private key indexes: #{indexes.inspect}"
    end
    
    # These indexes are brute-forced in the block above.
    [70, 227, 455, 524, 530, 583, 
    1150, 1193, 1351, 1987, 
    2209, 2320, 2703, 2800, 2984, 
    3029, 3203, 3275, 3472, 3526, 3896, 3900, 
    4070, 4236, 4670, 4831, 4929, 
    5233, 5254, 5301, 5609, 5980, 
    6202, 6283, 6313, 6430, 6951, 
    7056, 7060, 7211, 7274, 7311, 7614, 7897, 
    8313, 8328, 8329, 8840, 8950, 8996, 
    9323, 9354].each do |i|
      key = keychain.derived_key(i, hardened: true)
      key.private_key.bytesize.must_equal 32
      key.public_key.bytesize.must_equal 33
      key.private_key.bytes[0].must_equal 0
      key2 = keychain.derived_key(i, hardened: false)
      key2.private_key.bytesize.must_equal 32
      key2.public_key.bytesize.must_equal 33
    end

    # same as BIP32.org and CoreBitcoin
    keychain.derived_key(70, hardened: true).address.to_s.must_equal '1FZQfsXwAoUcn9WVwbfRb4jMMkPJEozLWH'
    keychain.derived_key(70, hardened: true).private_key.bytes[0].must_equal 0x00
    keychain.derived_key(227, hardened: true).address.to_s.must_equal '1LRbeWJC3sLGRk7ob82djVYTNhsH2UdR4f'
    keychain.derived_key(227, hardened: true).private_key.bytes[0].must_equal 0x00
    keychain.derived_key(455, hardened: true).address.to_s.must_equal '1HSr4B5Hr3hc7vAzNHbp7SV7rsFzUhQSeF'
    keychain.derived_key(455, hardened: true).private_key.bytes[0].must_equal 0x00
  end

  it "should verify a certain regression test" do
    extprv = "xprv9s21ZrQH143K3ZhiFsU612wiYCnd5miCTnWRMRJCmbTUxnn3F2WXuTXcoEyWpsit8ZqS5ddNvsoaEQuwzNwH8nmVDS24NwHbiu5oCrj85Kz"
    keychain = Keychain.new(xprv: extprv)
    key0 = keychain.derived_keychain(0, hardened: false).key
    # puts "UNCOMPR: #{key0.uncompressed_key.address.to_s}"
    # puts "  COMPR: #{key0.compressed_key.address.to_s}"
    # puts "DEFAULT: #{key0.address.to_s}"
    # Test reports:       1MLjpNJZ3KZUdd5J9ZVnhxjFioC8DnhSr4
    # BIP32.org reports:  15aALBTZkDrW8iZBKXrUHQo9dPJtGPEHSy
    key0.address.to_s.must_equal "15aALBTZkDrW8iZBKXrUHQo9dPJtGPEHSy"
  end

  it "should support conversion to public keychain" do
    seed = "000102030405060708090a0b0c0d0e0f".from_hex
    master = Keychain.new(seed: seed)

    m0prv = master.derived_keychain(0, hardened:true)
    m0prv_pub = m0prv.public_keychain

    m0prv.private?.must_equal true
    m0prv.public?.must_equal false
    m0prv.hardened?.must_equal true

    m0prv_pub.extended_public_key.must_equal m0prv.extended_public_key
    m0prv_pub.extended_private_key.must_equal nil
    m0prv_pub.private?.must_equal false
    m0prv_pub.public?.must_equal true
    m0prv_pub.hardened?.must_equal true

    m0prv_pub2 = Keychain.new(extended_key: m0prv.extended_public_key)
    m0prv_pub2.must_equal m0prv_pub
  end

  it "should support public-only derivation" do
    keychain = Keychain.new(xpub: "xpub661MyMwAqRbcFW31YEwpkMuc5THy2PSt5bDMsktWQcFF8syAmRUapSCGu8ED9W6oDMSgv6Zz8idoc4a6mr8BDzTJY47LJhkJ8UB7WEGuduB")
    m0pub = keychain.derived_keychain(0)
    m0pub.extended_public_key.must_equal "xpub69H7F5d8KSRgmmdJg2KhpAK8SR3DjMwAdkxj3ZuxV27CprR9LgpeyGmXUbC6wb7ERfvrnKZjXoUmmDznezpbZb7ap6r1D3tgFxHmwMkQTPH"
    m0pub.extended_private_key.must_equal nil
  end
end
