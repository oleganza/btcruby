[Index](index.md)

BTC::WIF
========

A subclass of [BTC::Address](address.md) that represents a serialized private [key](key.md) in a Wallet Import Format (WIF), also known as "sipa format".

Initializers
------------

#### new(string: *String*)

Returns a new WIF by parsing a [Base58Check](base58.md)-encoded string (must be a valid WIF string).

#### new(private\_key: *String*, network: *BTC::Network*, public\_key\_compressed: *false|true*)

Returns a new WIF with the 32-byte binary string `private_key`.

If `network` is not specified, [BTC::Network.default](network.md#default) is used.

If `public_key_compressed` is not specified, `false` is used.

#### new(key: *BTC::Key*, network: *BTC::Network*, public\_key\_compressed: *false|true*)

Returns a new WIF with [key.private_key](key.md).

Raises `ArgumentError` if `key` does not have a `private_key` component.

If `network` is not specified, `key.network` is used (instance of [BTC::Network](network.md)).

If `public_key_compressed` is not specified, `key.public_key_compressed` is used.


Instance Methods
----------------

#### key

Returns a [BTC::Key](key.md) instance represented by the WIF. The returned object inherits `network` and `public_key_compressed` attributes.

#### private_key

Returns raw binary 32-byte private key stored in WIF.

#### to_s

Returns string representation of the WIF in [Base58Check](base58.md) encoding.

#### public_address

Returns [BTC::PublicKeyAddress](p2pkh.md) instance corresponding to this key's public key.

#### public\_key\_compressed

Returns `true` or `false` depending on whether the corresponding [public key](key.md) should be compressed (33 bytes) or not (65 bytes).

#### network

Returns a [BTC::Network](network.md) instance based on the version prefix of the address (mainnet or testnet).

#### version

Returns an integer value of the one-byte prefix of the WIF encoding. 128 for mainnet, 239 for testnet.

#### p2pkh?

Returns `false`.

#### p2sh?

Returns `false`.

