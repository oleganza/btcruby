[Index](index.md)

BTC::Address
============

BTC::Address is a base class for [P2PKH](p2pkh.md), [P2SH](p2sh.md) addresses and [WIF](wif.md) private key serialization format. It is defined in **address.rb**.

Use BTC::Address to *decode* addresses of the unknown type (or when it does not matter). Use subclasses to *encode* addresses of a specific type.

Subclasses
----------

* [BTC::PublicKeyAddress](p2pkh.md)
* [BTC::ScriptHashAddress](p2sh.md)
* [BTC::WIF](wif.md)

Class Methods
-------------

#### parse(*argument*)

If `argument` is a String, parses it and returns an instance of one of the concrete subclasses of BTC::Address.

If `argument` is a subclass of BTC::Address returns `argument`.

```ruby
>> Address.parse("1CBtcGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG")
=> #<BTC::PublicKeyAddress:1CBtcGiv...>

>> Address.parse("3NukJ6fYZJ5Kk8bPjycAnruZkE5Q7UW7i8")
=> #<BTC::ScriptHashAddress:3NukJ6fY...>

>> Address.parse("5KQntKuhYWSRXNqp2yhdXzjekYAR7US3MT1715Mbv5CyUKV6hVe")
=>  #<BTC::WIF:5KQntKuh... privkey:d20b62cd... (uncompressed pubkey)>
```

Instance Methods
----------------

#### data

Returns an underlying binary string stored within an address.
For [WIF](wif.md) format it is a 32-byte private key.
For [P2PKH](p2pkh.md) or [P2PSH](p2sh.md) addresses it is a 20-byte hash.

#### to_s

Returns string representation of the address in [Base58Check](base58.md) encoding.

#### network

Returns a [BTC::Network](network.md) instance based on version prefix of the address (mainnet or testnet).

#### version

Returns an integer value of the one-byte prefix of the address.

#### public_address

Returns a corresponding public address. Typically returns `self`, but for [WIF](wif.md) returns
an address based on the public key corresponding to the WIF-encoded private key.

#### p2pkh?

Returns `true` if this address is a subclass of [PublicKeyAddress](p2pkh.md). Otherwise returns `false`.

#### p2sh?

Returns `true` if this address is a subclass of [ScriptHashAddress](p2sh.md). Otherwise returns `false`.

#### ==

Returns `true` if underlying data and versions of both addresses match.
