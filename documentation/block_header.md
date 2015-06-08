[Index](index.md)

BTC::BlockHeader
================

Block header is a part of the [block](block.md) that contains date, merkle root of the block's [transactions](transaction.md) and additional data related to proof-of-work.

Class Methods
-------------

#### genesis_mainnet

Returns a genesis block header for [mainnet](network.md#mainnet).
See also [BTC::Network#genesis_block_header](network.md#genesis_block_header).

#### genesis_testnet

Returns a genesis block header for [testnet](network.md#testnet).
See also [BTC::Network#genesis_block_header](network.md#genesis_block_header).

Initializers
------------

#### new(data: *String*)

Returns a new block header initialized with a binary string in [wire format](wire_format.md).
Raises `ArgumentError` if block header is incomplete or incorrectly encoded.

#### new(stream: *IO*)

Returns a new block header initialized with data in [wire format](wire_format.md) read from a given stream.
Raises `ArgumentError` if block header is incomplete or incorrectly encoded.

#### new(*attributes*)

Returns a new block header with named [attributes](#attributes). All attributes are optional and have appropriate default values.

```ruby
BlockHeader.new(
  version: 2,
  previous_block_id: "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f",
  merkle_root: "...",
  timestamp: ...)
```

Attributes
----------

#### version

Block version (1 or 2).

#### previous\_block\_hash

Binary hash of the previous block.

#### previous\_block\_id

Hex big-endian hash of the previous block. See [Hash↔ID Conversion](hash_id.md).

#### merkle_root

Binary root hash of the transactions’ merkle tree.

#### timestamp

32-bit unsigned UNIX timestamp.

#### time

Time object derived from timestamp

#### bits

Proof-of-work target in a compact form (uint32). See [Proof-of-Work Conversion Routines](proof_of_work.md).

#### nonce

Proof-of-work nonce (uint32 value iterated during mining).

#### height

Optional height in the block chain (genesis block has height 0).
Not stored within block's [binary representation](#data).
Third party APIs may set this value for user’s convenience.

#### confirmations

Optional number of the confirmations for transactions in this block.
If this block is the latest one, `confirmations` equals 1.
Not stored within block's [binary representation](#data).
Third party APIs may set this value for user’s convenience.


Instance Methods
----------------

#### block_hash

Binary hash of the block header. Equals `SHA256(SHA256(header_data))`.

#### block_id

Hex big-endian hash of the block header. See [Hash↔ID Conversion](hash_id.md).

#### header_data

Returns block’s header data in [wire format](wire_format.md).

#### data

Returns `header_data`.

#### dup

Returns a copy of the block header.

#### ==

Returns `true` if binary representation of both block headers is equal (external attributes `height`, `confirmations` are ignored).
