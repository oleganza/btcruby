# Implementation of [OpenAssets protocol](https://github.com/OpenAssets/open-assets-protocol/blob/master/specification.mediawiki).
# * AssetID uniquely identifies an asset and conditions of issuance.
# * AssetAddress is an address format that allows sending and receiving assets.
# * Asset represents an asset source (includes AssetID and output).
# * AssetMarker represents a marker specifying asset issuance and transfer.
# 
# Tasks:
# * Issuing a new asset.
# * Issuing more units of a given asset. If the issuing address holds some assets, they must be re-created.
# * Tracking asset origin via proofchain of transactions with block merkle paths.
# * Transferring assets.
# * Transferring assets with payment in the same transaction.
# * Non-interactive decentralized order book.
# * Supporting issue-once assets (anchored to a genesis transaction ID).
# * Supporting stock split (AssetV2 is issued by consuming AssetV1, validating software must validate AssetV2 accordingly).
# * Supporting key rotation (can be done using the same technique as with stock split). Maybe use metadata to link to a previous asset.
require_relative 'open_assets/asset_id.rb'
require_relative 'open_assets/asset_address.rb'
require_relative 'open_assets/asset.rb'
require_relative 'open_assets/asset_marker.rb'
require_relative 'open_assets/asset_transaction.rb'
require_relative 'open_assets/asset_transaction_input.rb'
require_relative 'open_assets/asset_transaction_output.rb'
require_relative 'open_assets/asset_processor.rb'
require_relative 'open_assets/asset_transaction_builder.rb'
require_relative 'open_assets/asset_definition.rb'
