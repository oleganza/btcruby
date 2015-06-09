[Index](index.md)

Core Extensions
===============

Core Extensions are convenience methods available on standard classes like `String`. 
We do not extend core classes by default to avoid conflicts with other libraries and your own extensions. 
To enable convenience methods, include `btcruby/extensions.rb` in your application.

Extensions are automatically available in BTCRuby interactive console `bin/console` and in unit tests.

String Extensions
-----------------

#### to\_wif(network: *BTC::Network*, public\_key\_compressed: *false|true*)

Converts a binary string representing a 32-byte private key to [WIF](wif.md) format.

If `network` is not specified, [BTC::Network.default](network.md#default) is used.

If `public_key_compressed` is not specified, `false` is used.


#### from_wif

Converts [WIF-encoded](wif.md) string to a raw 32-byte [private key](key.md#private_key).
Raises `FormatError` if the receiver is not a valid WIF-encoded string.

#### to_hex

Converts a binary string to a hex-encoded string.

#### from_hex

Converts a hex-encoded string to a binary string. 
Raises `FormatError` if the receiver is not a valid hex-encoded string.

#### sha1

Returns a binary string compressed using [SHA-1](http://en.wikipedia.org/wiki/SHA-1) algorithm.

#### sha256

Returns a binary string compressed using [SHA-256](http://en.wikipedia.org/wiki/SHA-2) algorithm.

#### sha512

Returns a binary string compressed using [SHA-512](http://en.wikipedia.org/wiki/SHA-2) algorithm.

#### ripemd160

Returns a binary string compressed using [RIPEMD-160](http://en.wikipedia.org/wiki/RIPEMD) algorithm.

#### hash256

Returns a binary string compressed using two passes of [SHA-256](http://en.wikipedia.org/wiki/SHA-256) algorithm. Known in Bitcoin as *Hash256*.

#### hash160

Returns a binary string compressed using composition `ripemd160(sha256(string))`. Known in Bitcoin as *Hash160*.
