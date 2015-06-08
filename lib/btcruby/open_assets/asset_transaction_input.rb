# Implementation of OpenAssets protocol.
# https://github.com/OpenAssets/open-assets-protocol/blob/master/specification.mediawiki
module BTC
  class AssetTransactionInput
    attr_accessor :index
    attr_accessor :transaction_input # BTC::TransactionInput

    # Verified inputs with `asset_id == nil` are *uncolored*.
    # Non-verified inputs are not known to have assets associated with them.
    attr_accessor :asset_id
    attr_accessor :value
    attr_accessor :verified # true if asset_id and value are verified and can be used.

    def initialize(transaction_input: nil, asset_id: nil, value: nil, verified: false)
      raise ArgumentError, "No transaction_input provided" if !transaction_input
      @transaction_input = transaction_input
      @index = transaction_input ? transaction_input.index : nil
      @asset_id = asset_id
      @value = value
      @verified = !!verified
    end

    # Input is verified when we know for sure if it's colored or not and if it is,
    # what asset and how much is associated with it.
    def verified?
      !!@verified
    end

    # Input is colored when it has AssetID and a positive value.
    def colored?
      !!@asset_id && @value && @value > 0
    end
    
    def index
      @index ||= @transaction_input.index
    end

    def assets_data
      data = "".b
      data << WireFormat.encode_uint8(@verified ? 1 : 0)
      data << WireFormat.encode_string(@asset_id ? @asset_id.hash : "".b)
      data << WireFormat.encode_int64le(@value.to_i)
      data
    end
    
    # Returns total length read
    def parse_assets_data(data, offset: 0)
      v, len = WireFormat.read_uint8(data: data, offset: offset)
      raise ArgumentError, "Invalid data: verified flag" if !v
      asset_hash, len = WireFormat.read_string(data: data, offset: len) # empty or 20 bytes
      raise ArgumentError, "Invalid data: asset hash" if !asset_hash
      value, len = WireFormat.read_int64le(data: data, offset: len)
      raise ArgumentError, "Invalid data: value" if !value
      @verified = (v == 1)
      @asset_id = asset_hash.bytesize > 0 ? AssetID.new(hash: asset_hash) : nil
      @value = value
      len
    end

    def ==(other)
      super(other) || self.transaction_input == other.transaction_input
    end
  end
end
