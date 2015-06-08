[Index](index.md)

BTC::WireFormat
===============

WireFormat module implements routines dealing with parsing and writing protocol messages.
All functions are also available as methods of `BTC::WireFormat` object.

Various structures have a variable-length data prepended by a length prefix which is itself of variable length.
This length prefix is a variable-length integer, *varint* (aka *CompactSize*).

NB. *varint* refers to what Satoshi called [CompactSize](https://en.bitcoin.it/wiki/Protocol_specification#Variable_length_integer). 
BitcoinQT has later added even more compact format called *CVarInt* to use in its local block storage. *CVarInt* is not implemented here.

Value Encoded   | Storage Size (bytes)   | Format
:---------------|:-----------------------|:----------------------------
 < 0xfd         | 1                      | uint8_t
 ≤ 0xffff       | 3                      | 0xfd followed by the value as little endian uint16_t
 ≤ 0xffffffff   | 5                      | 0xfe followed by the value as little endian uint32_t
 > 0xffffffff   | 9                      | 0xff followed by the value as little endian uint64_t


Module Functions
----------------

#### read_varint(data: *String*, offset: *Integer*)
#### read_varint(stream: *IO*, offset: *Integer*)

Returns `[value, length]` by reading from binary string `data` or `stream`. 
Value is a decoded integer value. Length is number of bytes read (including offset bytes).

In case of failure, returns `[nil, length]` where `length` is a number of bytes read before the error was encountered.

Default `offset` is 0.


#### encode_varint(*integer*)

Returns binary varint representation of `integer`.


#### write_varint(integer, data: *String*)
#### write_varint(integer, stream: *IO*)

Encodes the `integer` and appends it to binary string `data` or writes to `stream`. 

Returns binary varint representation of `integer`.


#### read_string(data: *String*, offset: *Integer*)
#### read_string(stream: *IO*, offset: *Integer*)

Returns `[string, length]` where `length` is number of bytes read (includes length prefix and offset bytes).

In case of failure, returns `[nil, length]` where `length` is a number of bytes read before the error was encountered.

Default `offset` is 0.


#### encode_string(*string*)

Returns binary representation of `string` (equals the string itself prepended with its byte length in varint format).


#### write_string(string, data: *String*)
#### write_string(string, stream: *IO*)

Encodes the `string` and appends it to binary string `data` or writes to `stream`. 

Returns binary representation of `string` (that is, with varint length prefix).
