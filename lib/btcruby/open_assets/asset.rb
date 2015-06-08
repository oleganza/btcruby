module BTC
  # Implementation of OpenAssets protocol.
  # https://github.com/OpenAssets/open-assets-protocol/blob/master/specification.mediawiki
  class Asset
        
    # BTC::AssetID instance identifying this asset.
    attr_accessor :asset_id
    
    # Binary 160-bit identifier of the asset (same as `asset_id.hash`)
    attr_accessor :identifier_binary
    
    # Optional attributes, set either by initializer when possible, or externally.
    attr_accessor :script
    attr_accessor :output
    
    # Initializes assets with one of the following:
    # * script - a BTC::Script instance.
    # * output - a BTC::TransactionOutput instance that issues the asset.
    # * asset_id - a Base58 identifier of the asset or BTC::AssetID instance.
    def initialize(asset_id: nil, script: nil, output: nil, network: nil)
      if script || output
        script ||= output.script
        @output = output
        @script = script
        @identifier_binary = BTC::Data.hash160(script.data)
        @asset_id = AssetID.new(hash: @identifier_binary, network: network)
      elsif asset_id
        @asset_id = Address.parse(asset_id)
        @identifier_binary = @asset_id.hash
      else
        raise ArgumentError, "Either asset_id, script or output must be specified."
      end
    end
  end
end
