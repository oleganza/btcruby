require_relative 'spec_helper'

describe BTC::KeychainGroup do

  describe "#multisig_script" do
    let(:extended_private_keys) do
      [
        "xprvA1XSPm4ktCeuiLSD6vYeY31EPBUjE55rYhtvviSD873YZw4rvL9nz7qf57JF7aYBsbPnwnG5PtERV63H3mHoZyuKiMddWL4ZmwSzHPHSGhX",
        "xprvA28GaehL72bWdThY1sW7dFfraTYVnxKKLXHLuUN2RbzhHCnRKLenrZYcgnCCZymErJf1zpBiaVmpEf7WtpXR1vKVKteZBcdJr7rJBLT6xG2",
        "xprv9zodTwqJX7DHJQd6Dk7uwGNCuX1aJGoc6zD3dyaJnoFYRsBze3FG6BE2YEQdJUQ7XYPFyfD5ijLNym9BnpgCgcAorhzyfrM2cja1eG3MC3n",
      ]
    end

    context "from extended_keys" do
      it "generates a multisig_script based on the derived keys at the given index and number of signatures_required" do
        keychain_group = BTC::KeychainGroup.new(extended_keys: extended_private_keys)

        multisig_script_0 = keychain_group.
          multisig_script(index: 0, signatures_required: 2)
        multisig_address_0 = multisig_script_0.
          p2sh_script.standard_address.to_s
        expect(multisig_address_0).to eq "3KBxrmV2Ye3BN3NQHva3jFnrbgwfFEDLne"

        multisig_script_19 = keychain_group.
          multisig_script(index: 19, signatures_required: 2)
        multisig_address_19 = multisig_script_19.
          p2sh_script.standard_address.to_s
        expect(multisig_address_19).to eq "3QMpum8wDfKNtPCe1AbXy5rSf9mfg3U8zr"
      end
    end
  end

  describe "#standard_address" do
    context "given private mainnet extended_keys" do
      let(:extended_keys) do
        [
          "xprvA1cu7c1sJxuwBGcDGx7bZweUAR9FeFzCM9mbHfY6gZwkyMEaY8kyEWFNrJQGmoM6Cb56s6JtiSUFGNoo9bybDCPcZTRRnd6YE7QLtoYjj41",
          "xprvA1MEWXKmoW6CDNUFnDw5Ccc4AosFy5jrBTeG7NVTQ5FFFDijVL1PEdTNzJQsxR29YmtbUuoQ2ocQBBgkDMgxBnQusVmPZyrCyAPQqebmxze",
        ]
      end
      let(:keychain_group) do
        BTC::KeychainGroup.new(extended_keys: extended_keys)
      end

      it "returns the multisig address at index and for the signatures_required" do
        address_0 = keychain_group.
          standard_address(index: 0, signatures_required: 1).to_s
        expect(address_0).to eq "33E6C9wpDVfmBhqy3gX8dBNQXsbBEEE5gj"

        address_8 = keychain_group.
          standard_address(index: 8, signatures_required: 1).to_s
        expect(address_8).to eq "37AW4wGcSVhY4vm4FonuziZmKDbr9ZEjLs"

        address_9 = keychain_group.
          standard_address(index: 9, signatures_required: 1).to_s
        expect(address_9).to eq "36MY8Vbk48Uc7M5kRS9rzQ6jRRj3g2iTDV"
      end
    end

    context "given public mainnet extended_keys" do
      let(:extended_keys) do
        [
          "xpub6EcFX7Ym9LUEPkggNyebw5bCiSyk3ii3iNhC63wiEuUjr9Zj5g5DnJZrhYLTmbSPCDhuH4qZ4PkKTmubR3auDJKjxdKXkxFoh8ELj698Mf8",
          "xpub6ELav2rfdseVRrYitFU5ZkYniqhkNYThYgZruku4xQnE823t2sKdnRmrqcgVie96i9XUQvvsJcTH4nRB6xvd2o2KMaG8amhBpcJ8AoqEU6o",
        ]
      end
      let(:keychain_group) do
        BTC::KeychainGroup.new(extended_keys: extended_keys)
      end

      it "returns the multisig address at index and for the signatures_required" do
        address_0 = keychain_group.
          standard_address(index: 0, signatures_required: 1).to_s
        expect(address_0).to eq "33E6C9wpDVfmBhqy3gX8dBNQXsbBEEE5gj"

        address_8 = keychain_group.
          standard_address(index: 8, signatures_required: 1).to_s
        expect(address_8).to eq "37AW4wGcSVhY4vm4FonuziZmKDbr9ZEjLs"

        address_9 = keychain_group.
          standard_address(index: 9, signatures_required: 1).to_s
        expect(address_9).to eq "36MY8Vbk48Uc7M5kRS9rzQ6jRRj3g2iTDV"
      end
    end

    context "given public testnet extended_keys" do
      let(:extended_keys) do
        [
          "tpubDF7aivmHsi1vjna9uiTHuXsxpa76c69s5pYRqk9cTAMVmPm8B3SQ9xYUB5Lt3wvFbLyY1GcgU1saGHc4bpDK7cyfNLHjxoh68tBRFdeWjh6",
          "tpubDEfAYsrZ6Bd9S3Qdx6JvL7E9kCXUDZiFprPLvgMk711VturA5j2GLWK322FgWNUz2SYseJbsnuRUyosbajP22yXruyhHXnxRqcbb5QVvKvh",
        ]
      end
      let(:keychain_group) do
        BTC::KeychainGroup.new(extended_keys: extended_keys)
      end

      it "returns the multisig address at index and for the signatures_required" do
        # NOTE: could not find another tool, like https://coinb.in/#newMultiSig
        # to generate multisig testnet addresses. The addresses we're testing
        # against below were generated from Btcruby
        address_0 = keychain_group.
          standard_address(index: 0, signatures_required: 1).to_s
        expect(address_0).to eq "2MwvRcRjDTQW73iwcQ6p5jt8wSWvtxdp34N"
      end
    end

    context "given private testnet extended_keys" do
      let(:extended_keys) do
        [
          "tprv8iRYaWj3jLLFrKYN24nhW8DrFYbASkxxWWweZE7K2tZ6vuWMYecoyTvbzxgp4vyCYXRdc7YMyuX7XTVVPWLwk3im8t5FsA5e1o4ihXHzkvg",
          "tprv8hy8QTpJwowUYaNr4SeKvha3BB1Y4EXMFYnZeAKSgjD74RbPTLCgA1hAqteupZ4x4ps1E4Pb2aZcVasZfEdELhUVjcAssRwcWHHbcEU9kuM",
        ]
      end
      let(:keychain_group) do
        BTC::KeychainGroup.new(extended_keys: extended_keys)
      end

      it "returns the multisig address at index and for the signatures_required" do
        # NOTE: could not find another tool, like https://coinb.in/#newMultiSig
        # to generate multisig testnet addresses. The addresses we're testing
        # against below were generated from Btcruby
        address_0 = keychain_group.
          standard_address(index: 0, signatures_required: 1).to_s
        expect(address_0).to eq "2MwvRcRjDTQW73iwcQ6p5jt8wSWvtxdp34N"
      end
    end
  end

end
