module BTC
  class KeychainGroup

    attr_reader :extended_keys

    def initialize(extended_keys:)
      @extended_keys = extended_keys
    end

    def multisig_script(index: nil, signatures_required:)
      pubkeys = derived_keys(index).map(&:public_key)

      BTC::Script.multisig(
        public_keys: pubkeys,
        signatures_required: signatures_required,
      )
    end

    def standard_address(index:, signatures_required:)
      multisig_script(index: index, signatures_required: signatures_required).
        p2sh_script.standard_address(network: network).to_s
    end

    private

    def network
      networks = keychains.map(&:network).uniq
      return networks[0] if networks.size == 1
      fail(
        ArgumentError,
        "extended_keys seem to be a combination of mainnet and testnet"
      )
    end

    def keychains
      @keychains ||= extended_keys.map do |extended_key|
        Keychain.new(extended_key: extended_key)
      end
    end

    def derived_keychains(index_or_path)
      keychains.map { |keychain| keychain.derived_keychain(index_or_path) }
    end

    def derived_keys(index_or_path)
      derived_keychains(index_or_path).map(&:key)
    end

  end
end
