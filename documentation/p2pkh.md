[Index](index.md)

BTC::PublicKeyAddress
=====================

A subclass of [BTC::Address](address.md) that represents an address based on the public key (pay-to-public-key-hash, P2PKH).

Initializers
------------

#### new(string: *String*)

Returns a new address by parsing a [Base58Check](base58.md)-encoded string that must represent a valid P2PKH address.

#### new(hash: *String*, network: *BTC::Network*)

Returns a new address with a 20-byte binary string `hash`.

If `network` is not specified, [BTC::Network.default](network.md#default) is used.

#### new(public_key: *String*, network: *BTC::Network*)

Returns a new address with a hash of the binary string `public_key`.

If `network` is not specified, [BTC::Network.default](network.md#default) is used.

#### new(key: *BTC::Key*, network: *BTC::Network*)

Returns a new address with a hash of the `key.public_key`.

If `network` is not specified, `key.network` is used.


Instance Methods
----------------

#### hash

Returns a 20-byte binary hash stored within the address.

#### to_s

Returns string representation of the address in [Base58Check](base58.md) encoding.

#### network

Returns a [BTC::Network](network.md) instance based on the version prefix of the address (mainnet or testnet).

#### version

Returns an integer value of the one-byte prefix of the address. 0 for mainnet, 111 for testnet.

#### public_address

Returns `self`.

#### p2pkh?

Returns `true`.

#### p2sh?

Returns `false`.

#### script

Returns [BTC::Script](script.md) instance that can be used in the [transaction output](transaction_output.md) to send bitcoins to this address.




