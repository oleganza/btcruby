[Index](index.md)

BTC::ScriptHashAddress
=====================

A subclass of [BTC::Address](address.md) that represents an address based on the redeem [script](script.md) (pay-to-script-hash, P2SH).

Initializers
------------

#### new(string: *String*)

Returns a new address by parsing a [Base58Check](base58.md)-encoded string that must represent a valid P2SH address.

#### new(hash: *String*, network: *BTC::Network*)

Returns a new address with a 20-byte binary `hash`.

If `network` is not specified, [BTC::Network.default](network.md#default) is used.

#### new(redeem_script: *BTC::Script*, network: *BTC::Network*)

Returns a new address with a hash of the [BTC::Script](script.md) (so-called “redeem script”).

If `network` is not specified, [BTC::Network.default](network.md#default) is used.


Instance Methods
----------------

#### hash

Returns a 20-byte binary hash stored within the address.

#### to_s

Returns string representation of the address in [Base58Check](base58.md) encoding.

#### network

Returns a [BTC::Network](network.md) instance based on the version prefix of the address (mainnet or testnet).

#### version

Returns an integer value of the one-byte prefix of the address. 5 for mainnet, 196 for testnet.

#### public_address

Returns `self`.

#### p2pkh?

Returns `false`.

#### p2sh?

Returns `true`.

#### script

Returns [BTC::Script](script.md) instance that can be used in the [transaction output](transaction_output.md) to send bitcoins to this address. 

Note: do not confuse this with the “redeem script” that is compressed within the address's *hash*. 

