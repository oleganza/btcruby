[Index](index.md)

BTC::Keychain
=============

BTC::Keychain is an implementation of BIP32 "[Hierarchical Deterministic Wallets](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki)" (HD Wallets).

Keychain encapsulates either a pair of "extended" keys (private and public), or only a public extended key.
**Extended key** means the key (private or public) is accompanied by an extra 256 bits of entropy
called **chain code** and some metadata about its position in a tree of keys (depth, parent fingerprint, index).

Keychain allows to derive [keys](key.md) using an unsigned 32-bit integer called **index**.

Keychain has two modes of operation:

1. **Normal derivation** which allows to derive public keys separately from the private ones.
2. **Hardened derivation** which derives keys from the private keychain.

Derivation can be treated as a single key or as a new branch of keychains.
BIP43 and BIP44 propose a way for wallets to organize streams of keys using Keychain.

Examples
--------

Create a keychain with a seed, derive keychains and keys:

```ruby
keychain = Keychain.new(seed: "secret seed")
keychain.derived_keychain(0).xpub     # => "xpub68YTawrm7..."
keychain.derived_key(0).address.to_s  # => "1HosjTCbRD9og..."
```

You can derive keys using hardened method (`hardened` is `false` by default):

```ruby
keychain.derived_keychain(0, hardened: true).xpub     # => "xpub68YTawruT..."
keychain.derived_key(0, hardened: true).address.to_s  # => "14ELmCNCnku1Y..."
```

You can specify entire paths:

```ruby
keychain.derived_key("44'/0'/0'/0/0").address.to_s # => "1fY2x5v63a..."
```

Initializers
------------

#### new(seed: *String*, network: *BTC::Network*)

Returns a new `BTC::Keychain` instance initialized with a binary string `seed`.

To generate `seed`, you may use [BTC::Data.random_data](data.md#random_data)(16).

If `network` is not specified, [BTC::Network.default](network.md#default) is used.

#### new(extended_key: *String*)

Returns a new `BTC::Keychain` instance initialized with a given extended public or private key (`"xpub..."` or `"xprv..."`).

`network` attribute is set based on the encoding of the extended key. If `"tpub..."` or `"tprv..."` is used, `Network.testnet` is assigned.

#### new(xpub: *String*)

An alias to `new(extended_key: ...)`.

#### new(xprv: *String*)

An alias to `new(extended_key: ...)`.


Instance Methods
----------------

#### key

Instance of [BTC::Key](key.md) that is a "head" of this keychain.
If the keychain is public-only, `key` does not have a private component.

#### chain_code

A 32-byte binary "chain code" string used as an additional entropy in derivation procedure.

#### extended\_public\_key

A [Base58Check](base58.md)-encoded extended public key.
Starts with `xpub` for mainnet and `tpub` for testnet.

#### xpub

An alias to `extended_public_key`.

#### extended\_private\_key

A [Base58Check](base58.md)-encoded extended private key.
Starts with `xprv` for mainnet and `tprv` for testnet.

#### xprv

An alias to `extended_private_key`.

#### to_s

A [Base58Check](base58.md)-encoded extended key.
Returns `extended_private_key` if private, and `extended_public_key` if public.

#### identifier

A 160-bit binary identifier (aka "hash") of the keychain.
Equals `RIPEMD160(SHA256(key.public_key))`

#### fingerprint

32-bit unsigned integer extracted from `identifier`.

#### parent_fingerprint

A fingerprint of the parent keychain. Returns 0 for the master (root) keychain.

#### index

Index of this keychain (uint32) in the parent keychain. Returns 0 for master (root) keychain.

#### depth

Depth in the hierarchy (uint32). Returns 0 for master (root) keychain.

#### network

Returns a [BTC::Network](network.md) instance used to format extended public and private keys.

#### private?

Returns `true` if this keychain contains a private component (can derive both public and private keys).

#### public?

Returns `true` if this keychain does not contain a private component (can only derive public keys).

#### hardened?

Returns `true` if this keychain was derived using *hardened* method from its parent.
For master (root) keychain returns `false`.

#### public_keychain

Returns a public-only copy of the keychain.

#### derived_keychain(*index*, hardened: *false | true*)

Returns a derived keychain with a given `index`.

Raises `ArgumentError` if `index` is below zero or higher than 0x7fffffff.

If `hardened` is `true`, uses private key for hardened derivation.
If this is a public-only keychain, raises `BTCError`. Default value is `false`.

#### derived_keychain(*path*)

Returns a derived keychain with a given string `path`.
Path is specified as a sequence of integers separated by a forward slash `/`.
Integers can be suffixed with `'` to specify hardened derivation.
Path can be optionally prefixed with `m/`.

Raises `ArgumentError` if `path` is not a well-formed derivation path.

The following are equivalent:

```ruby
k.derived_keychain(0) == k.derived_keychain("m/0")
k.derived_keychain(1) == k.derived_keychain("1")
k.derived_keychain(2, hardened: true) == k.derived_keychain("2'")
k.derived_keychain(3).derived_keychain(4) == k.derived_keychain("3/4")
k.derived_keychain(5, hardened: true).derived_keychain(6) == k.derived_keychain("m/5'/6")
```

#### derived_key(*index*, hardened: *false | true*)

Equivalent to `derived_keychain(...).key`

#### derived_key(*path*)

Equivalent to `derived_keychain(path).key`
