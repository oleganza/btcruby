[Index](index.md)

BTC::Base58
===========

**Base58** and **Base58Check** are two encodings invented by Satoshi for Bitcoin [addresses](addresses.md)
to make sure they don't contain ambiguous characters and can be selected with a double click.

Note: you normally do not use Base58 directly. To encode/decode Bitcoin addresses, use [BTC::Address](address.md) class.
To encode/decode private keys in WIF format, use [BTC::WIF](wif.md) class.

Satoshi:

> Why base-58 instead of standard base-64 encoding?
> - Don't want 0OIl characters that look the same in some fonts and could be used to create visually identical looking account numbers.
> - A string with non-alphanumeric characters is not as easily accepted as an account number.
> - E-mail usually won't line-break if there's no punctuation to break at.
> - Double-clicking selects the whole number as one word if it's all alphanumeric.

Base58 treats a binary string as a big-endian integer and encodes it in Base58 alphabet:

```
123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz
```

Leading zero bytes are encoded as repeated "1"s.

**Base58Check** appends a 4-byte portion of [Hash256](hash_functions.md) of the binary string as a checksum, then encodes the resulting string in Base58.

Module Functions
----------------

#### base58\_from\_data(*data*)

Returns a Base58-encoded string for a given binary string `data`.

#### data\_from\_base58(*string*)

Returns a binary string decoded from Base58-encoded `string`.

Raises `FormatError` if encoding is not valid.

#### base58check\_from\_data(*data*)

Returns a Base58-encoded string with appended checksum for a given binary string `data`.

#### data\_from\_base58check(*string*)

Returns a binary string decoded from Base58Check-encoded `string`.

Raises `FormatError` if checksum is not valid or encoding is not valid.

