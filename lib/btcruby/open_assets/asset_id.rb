module BTC
  # Represents an Asset ID.
  class AssetID < BTC::Hash160Address
    
    def self.mainnet_version
      23 # "A" prefix
    end

    def self.testnet_version
      115
    end

    # Instantiates AssetID with output, output script or raw hash.
    # To compute an Asset ID for the Asset Definition file, use `trim_script_prefix: true`.
    def initialize(string: nil, hash: nil, network: nil, _raw_data: nil, script: nil, trim_script_prefix: false)
      if script
        script = script.without_dropped_prefix_data if trim_script_prefix
        super(hash: BTC.hash160(script.data), network: network)
      else
        super(string: string, hash: hash, network: network, _raw_data: _raw_data)
      end
    end
  end
end
