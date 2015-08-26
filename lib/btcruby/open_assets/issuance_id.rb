module BTC
  # Represents a distinct issuance of any given asset.
  # Hash160(tx hash || txout index || amount)
  class IssuanceID < BTC::Hash160Address

    register_class self

    def self.mainnet_version
      63 # 'S' prefix ('single', 'issuance')
    end

    def self.testnet_version
      125 # 's' prefix
    end

    def initialize(string: nil, hash: nil, network: nil, outpoint: nil, _raw_data: nil)
      if outpoint
        data = outpoint.transaction_hash + WireFormat.encode_uint32be(outpoint.index)
        super(hash: BTC.hash160(data), network: network)
      else
        super(string: string, hash: hash, network: network, _raw_data: _raw_data)
      end
    end
  end
end
