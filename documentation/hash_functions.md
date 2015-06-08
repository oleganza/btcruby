[Index](index.md)

BTC::HashFunctions
==================

Bitcoin uses various hash functions, all of which are available in the module `BTC::HashFunctions`.
All functions take binary string arguments and return binary strings. 
Use [hex conversion methods](data.md) to convert string to/from hex encoding if needed.

You typically access these via `BTC` object:

```ruby
>> BTC.sha256("correct horse battery staple")
=> "\xc4\xbb\xcb\x1f..."
```

If you include [Core Extensions](extensions.md), you can use these and some other functions directly on the String:

```ruby
>> "correct horse battery staple".sha256.to_hex
=> "c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a"
```

Module Functions
----------------

#### sha1(*string*)

Returns a binary string compressed using [SHA-1](http://en.wikipedia.org/wiki/SHA-1) algorithm.

#### sha256(*string*)

Returns a binary string compressed using [SHA-256](http://en.wikipedia.org/wiki/SHA-2) algorithm.

#### sha512(*string*)

Returns a binary string compressed using [SHA-512](http://en.wikipedia.org/wiki/SHA-2) algorithm.

#### ripemd160(*string*)

Returns a binary string compressed using [RIPEMD-160](http://en.wikipedia.org/wiki/RIPEMD) algorithm.

#### hash256(*string*)

Returns a binary string compressed using two passes of [SHA-256](http://en.wikipedia.org/wiki/SHA-256) algorithm. Known in Bitcoin as *Hash256*.

#### hash160(*string*)

Returns a binary string compressed using composition `ripemd160(sha256(string))`. Known in Bitcoin as *Hash160*.

#### hmac_sha256(data: *String*, key: *String*)

Returns a result of [HMAC](http://en.wikipedia.org/wiki/Hash-based_message_authentication_code) using [SHA-256](http://en.wikipedia.org/wiki/SHA-2) hash.

#### hmac_sha512(data: *String*, key: *String*)

Returns a result of [HMAC](http://en.wikipedia.org/wiki/Hash-based_message_authentication_code) using [SHA-512](http://en.wikipedia.org/wiki/SHA-2) hash.

