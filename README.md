# BTCRuby

[![Build Status](https://magnum.travis-ci.com/oleganza/btcruby.svg?token=84LHn4zp2Z1676MxCHjR)](https://magnum.travis-ci.com/oleganza/btcruby)

BTCRuby aims at clarity, security and flexibility. The API is designed simultenously
with [CoreBitcoin](https://github.com/oleganza/CoreBitcoin) (Objective-C library) and polished on real-life applications.

## Documentation and Examples

Please see [BTCRuby Reference](documentation/index.md) for API documentation and examples.

## Basic Features

* Encoding/decoding of addresses, WIF private keys (`BTC::Address`).
* APIs to construct and inspect blocks, transactions and scripts.
* Native BIP32 and BIP44 ("HW Wallets") support (see `BTC::Keychain`).
* Explicit APIs to handle compressed and uncompressed public keys.
* Explicit APIs to handle mainnet/testnet (see `BTC::Network`)
* Consistent API for data encoding used throughout the library itself (see `BTC::Data` and `BTC::WireFormat`).
* Flexible transaction builder that can work with arbitrary data sources that provide unspent outputs.
* Handy extensions on built-in classes (e.g. `String#to_hex`) are optional (see `extensions.rb`).
* Optional attributes on Transaction, TransactionOutput and TransactionInput to hold additional data
  provided by 3rd party APIs.

## Advanced Features

* ECDSA signatures are deterministic and normalized according to [RFC6979](https://tools.ietf.org/html/rfc6979) 
  and [BIP62](https://github.com/bitcoin/bips/blob/master/bip-0062.mediawiki).
* Automatic normalization of existing ECDSA signatures (see `BTC::Key#normalized_signature`).
* Rich script analysis and compositing support (see `BTC::Script`).
* Powerful diagnostics API covering the entire library (see `BTC::Diagnostics`).
* Canonicality checks for transactions, public keys and script elements.
* Fee computation and signature script simulation for building transactions without signing them.
* Complete OpenAssets implementation: validating OpenAssets transactions, easy to use transaction builder, API for handling Asset Definition.

## Philosophy

* We use clear, expressive names for all methods and classes.
* Self-contained implementation. Only external dependency is `ffi` gem that helps linking directly with OpenSSL.
* For efficiency and consistency we use binary strings throughout the library (not the hex strings as in other libraries).
* We do not pollute standard classes with our methods. To use utility extensions like `String#to_hex` you should explicitly `require 'btcruby/extensions'`.
* We use OpenSSL `BIGNUM` implementation where compatibility is critical (instead of the built-in Ruby Bignum).
* We enforces canonical and determinstic ECDSA signatures for maximum compatibility and security using native OpenSSL functions.
* We treat endianness explicitly. Even though most systems are little-endian, it never hurts to show where indianness is important.

The goal is to provide a complete Bitcoin toolkit in Ruby.

## How to run tests

```
$ bundle install
$ rake
```

## Authors

* [Oleg Andreev](http://oleganza.com/)
* [Ryan Smith](http://r.32k.io)

