[Index](index.md)

Hash ↔ ID Conversion
======================

[Transactions](transaction.md) and [blocks](block.md) are identified by hashes of their binary contents.
In practice these hashes are typically presented as hex-encoded big-endian 256-bit integers which we call *IDs*.
*Transaction ID* and *Block ID* are computed by reversing the bytes of the original binary hash and then encoding it in hex. 

Most of the time, each object that exposes a binary *hash* attribute, also exposes a corresponding *id* attribute.
However, if you need to manually convert a *hash* to *id* or the other way around, use the following methods on the `BTC` object.

Functions
---------

#### BTC.hash\_from\_id(*hex\_string*)

Returns a binary hash string for a given hex string.

#### BTC.id\_from\_hash(*hash*)

Returns a hex-encoded identifier for a given binary hash string.
