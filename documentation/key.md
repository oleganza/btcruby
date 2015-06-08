[Index](index.md)

BTC::Key
========

Class BTC::Key encapsulates a pair of public and private keys (or a public key only)
and provides methods to sign messages and verify signatures.

**Private key** is a 256-bit integer encoded in a 32-byte big-endian binary string (always padded with zeros from the left).
Private key is used to sign messages. Private key can be `nil` for *public-only* BTC::Key instances.

**Public key** is a 33-byte or 65-byte binary string encoding coordinates of a point on
the elliptic curve [secp256k1](https://en.bitcoin.it/wiki/Secp256k1).
Public key is used to verify signatures.

Public key can be **compressed** (33 bytes) or **uncompressed** (65 bytes).
Compressed public key contains only an X coordinate of a point and recovers Y coordinate with extra arithmetic operations.
Uncompressed public key contains both X and Y coordinates. Both versions are equally capable of verifying signatures, but
resulting [addresses](p2pkh.md) are different (because hashes are different). [BIP32](keychain.md) standard uses only compressed public key for compactness and consistency.

If the BTC::Key instance contains only a public key, it can only verify signatures, but cannot create them.

Class Methods
-------------

#### validate\_private\_key\_range(*private_key*)

Returns `true` if data representing a private key is within a valid range for elliptic curve *secp256k1*.

#### validate\_public\_key(*public_key*)

Returns `true` if the raw binary public key is valid and well-formed.
Accepts both compressed and uncompressed public keys.
Logs detailed info using [BTC::Diagnostics](diagnostics.md).

#### validate\_script\_signature(*data*, verify\_lower\_s: true)

Returns `true` if the [script signature](signature.md) is valid.

If `verify_lower_s` is `true` (it is by default), then this method also verifies if the signature is canonical.

#### validate\_and\_normalize\_script\_signature(*script_sig*)

Validates [script signature](signature.md) and normalizes it if needed.

Returns `nil` if script signature is not valid (e.g. DER encoding is invalid, or [hash type](signature.md) is invalid).

Returns `script_sig` if it is a valid, canonical signature.

Returns a normalized ("lower s") version of `script_sig` if it is non-canonical.

#### normalized_signature(*signature*)

Returns a `sig` or a normalized version of `sig`.
Assumes signature is a valid plain DER-encoded ECDSA signature, otherwise raises `BTCError`.

Initializers
------------

#### random(public\_key\_compressed: *true|false*, network: *BTC::Network*)

Returns a new `BTC::Key` instance with a random `private_key`.

If `public_key_compressed` is not specified, `true` is used.

If `network` is not specified, [BTC::Network.default](network.md#default) is used.


#### new(private\_key: *String*, public\_key\_compressed: *true|false*, network: *BTC::Network*)

Returns a new `BTC::Key` instance with a given binary `private_key`.

If `private_key` is not within a valid range, raises `FormatError`.

If `public_key_compressed` is not specified, `true` is used.

If `network` is not specified, [BTC::Network.default](network.md#default) is used.


#### new(public_key: *String*, network: *BTC::Network*)

Returns a new `BTC::Key` instance with a given binary `public_key`.
This instance does not contain a private key and can only be used to verify signatures.

If `public_key` is not a valid compressed or uncompressed public key, raises `FormatError`.

If `network` is not specified, [BTC::Network.default](network.md#default) is used.


#### new(wif: *String*)

Returns a new `BTC::Key` instance with a private key decoded from [WIF](wif.md) string.

If `wif` is not a valid WIF-encoded string, raises `FormatError`.

Public key compression and `network` attributes are inherited from WIF.


Instance Methods
----------------

#### ecdsa_signature(*hash*)

Returns a binary DER-encoded ECDSA signature for a given binary string `hash` (typically 32-byte long).
Signature is normalized and uses deterministic nonce `k` based on private key and the `hash`.

Raises `ArgumentError` if receiver's private key is `nil`.

#### verify\_ecdsa\_signature(*signature*, *hash*)

Returns `true` if the binary DER-encoded `signature` for a given binary string `hash` is correctly verified
against the public key of the receiver.

#### public\_key\_compressed

Returns `true` or `false` depending on whether public key is compressed.

#### compressed_key

Returns a new `BTC::Key` instance with `public_key_compressed` set to `true`.

#### uncompressed_key

Returns a new `BTC::Key` instance with `public_key_compressed` set to `false`.

#### private_key

Returns a raw 32-byte private key or `nil` if it is a public-only key.

#### public_key

Returns a raw 33- or 65-byte public key depending on `public_key_compressed` value.

#### compressed\_public\_key

Returns a raw compressed 33-byte public key.

#### uncompressed\_public\_key

Returns a raw uncompressed 65-byte public key.

#### network

Returns a [BTC::Network](network.md) instance used by `address` method (mainnet or testnet).

#### address(network: *BTC::Network*)

Returns a [BTC::PublicKeyAddress](p2pkh.md) instance with a given `network`.

If `network` is not specified, `self.network` is used.

#### to_wif(network: *BTC::Network*)

Returns `private_key` encoded in [WIF](wif.md).

Returns nil if `private_key` is nil.

If `network` is not specified, `self.network` is used.

#### dup

Returns a new `BTC::Key` instance with the same `private_key`, `public_key` and `network`.

#### ==

Returns `true` if both instances have equal private and public keys.











