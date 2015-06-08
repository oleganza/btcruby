[Index](index.md)

BTC::Data
=========

`BTC::Data` module implements common routines dealing with binary strings.
All functions are also available as methods of `BTC::Data` object.

Module Functions
----------------

#### random_data(length = 32)

Returns a cryptographically secure random binary string of a given length. Default length is 32 bytes.

#### data\_from\_hex(string)

Returns a binary string decoded from a hex-encoded string.

Raises `FormatError` if argument is not a valid hex string.

#### hex\_from\_data(string)

Returns a hex-encoded string.

#### bytes\_from\_data(string)
#### bytes\_from\_data(string, offset: 0, limit: nil)
#### bytes\_from\_data(string, range: nil)

Returns an array of bytes from a given string.

If `offset` is specified, returns bytes starting with a given offset.

If `limit` is specified, limits number of bytes accordingly.

If `range` is specified, returns an array of bytes within the specified range.

#### data\_from\_bytes(bytes)

Returns a binary string made from the given array of bytes (integers).

#### ensure\_ascii\_compatible\_encoding(string, options = nil)

Returns `string` as-is if it is ASCII-compatible (that is, if you are interested in 7-bit characters exposed as `#bytes`).
If it is not, attempts to transcode to UTF8 replacing invalid characters if there are any.

If `options` are not specified, uses safe defaults: replaces unknown characters with a standard character.

If `options` are specified, they are used as-is for `String#encode` method.

#### ensure\_binary\_encoding(string)

Returns string as-is if it is already encoded in binary encoding (aka BINARY or ASCII-8BIT).
If it is not, converts to binary by calling standard method `#b`.
