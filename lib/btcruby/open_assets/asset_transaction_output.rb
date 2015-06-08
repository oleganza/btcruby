# Implementation of OpenAssets protocol.
# https://github.com/OpenAssets/open-assets-protocol/blob/master/specification.mediawiki
module BTC
  class AssetTransactionOutput
    KIND_ISSUE    = :issue
    KIND_TRANSFER = :transfer
    KIND_MARKER   = :marker

    attr_reader :index
    attr_accessor :transaction_output # BTC::TransactionOutput

    attr_accessor :kind
    attr_accessor :issue # if true, then it's an issue output
    attr_accessor :transfer # if true, then it's a transfer output
    attr_accessor :marker # if true, then it's a marker output

    # Verified outputs with `asset_id == nil` are *uncolored*.
    # Non-verified outputs are not known to have assets associated with them.
    attr_accessor :asset_id
    attr_accessor :value
    attr_accessor :verified # true if asset_id and value are verified and can be used.

    def initialize(transaction_output: nil, asset_id: nil, value: nil, verified: false, issue: nil, transfer: nil, marker: nil)
      raise ArgumentError, "No transaction_output provided" if !transaction_output
      @transaction_output = transaction_output
      @index = transaction_output ? transaction_output.index : nil
      @asset_id = asset_id
      @value = value
      @verified = !!verified
      self.issue = issue if issue
      self.transfer = transfer if transfer
      self.marker = marker if marker
    end

    # Output is verified when we know for sure if it's colored or not and if it is,
    # what asset and how much is associated with it.
    def verified?
      !!@verified
    end

    # Output is colored when it has AssetID and a positive value.
    def colored?
      !!@asset_id && has_value?
    end

    def has_value?
      !!@value && @value > 0
    end

    def issue=(issue)
      raise ArgumentError, "Can only set `issue` to true" if !issue
      self.kind = KIND_ISSUE
      issue
    end

    def transfer=(transfer)
      raise ArgumentError, "Can only set `transfer` to true" if !transfer
      self.kind = KIND_TRANSFER
      transfer
    end

    def marker=(marker)
      raise ArgumentError, "Can only set `marker` to true" if !marker
      self.kind = KIND_MARKER
      marker
    end

    def kind=(kind)
      @kind = kind
      @marker = nil
    end

    # Returns `true` if this output may issue new amount of some asset.
    def issue
      @kind == KIND_ISSUE
    end
    alias :issue? :issue

    # Returns `true` if this output may transfer new amount of some asset.
    def transfer
      @kind == KIND_TRANSFER
    end
    alias :transfer? :transfer

    # Returns `true` if this output corresponds to a marker output (always uncolored)
    def marker
      @marker ||= (@kind == KIND_MARKER ? AssetMarker.new(output: @transaction_output) : nil)
    end

    def marker?
      !!marker
    end

    def index
      @index ||= @transaction_output.index
    end

    def transaction_hash
      @transaction_output.transaction_hash
    end

    def transaction_id
      @transaction_output.transaction_id
    end

    def outpoint
      @transaction_output.outpoint
    end

    def outpoint_id
      @transaction_output.outpoint_id
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
      super(other) || self.transaction_output == other.transaction_output
    end
  end
end
