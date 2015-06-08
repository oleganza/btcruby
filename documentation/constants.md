[Index](index.md)

BTC Constants
=============

These are defined in **constants.rb**.

Units
-----

#### SATOSHI = 1

Satoshi is the smallest unit representable in Bitcoin [transactions](transaction.md).

#### COIN = 100\_000\_000

One bitcoin equals 100 million satoshis.

#### BIT = 100

1 bit is 100 satoshis (1 millionth of a bitcoin).


Network Rules
-------------

Changing these will result in incompatibility with other nodes.

#### MAX\_BLOCK\_SIZE = 1\_000\_000

The maximum allowed size for a serialized [block](block.md), in bytes.

#### MAX\_BLOCK\_SIGOPS = MAX\_BLOCK\_SIZE/50

The maximum allowed number of signature check operations in a [block](block.md).

#### MAX\_MONEY = 21\_000\_000 * COIN

No amount larger than this (in satoshis) is valid.

#### COINBASE\_MATURITY = 100

Coinbase transaction outputs can only be spent after this number of new blocks.

#### LOCKTIME\_THRESHOLD = 500\_000\_000

Threshold for [BTC::Transaction#lock_time](transaction.md): below this value it is interpreted 
as a [block](block.md) number, otherwise as UNIX timestamp.

#### BIP16\_TIMESTAMP = 1333238400

[P2SH](p2sh.md) BIP16 didn't become active until April 1, 2012.
All [transactions](transaction.md) before this timestamp should not be verified with P2SH rule.

#### MAX\_SCRIPT\_SIZE = 10000

Scripts longer than 10K bytes are invalid.

#### MAX\_SCRIPT\_ELEMENT\_SIZE = 520

Maximum number of bytes per "pushdata" [opcode](opcode.md).

#### MAX\_KEYS\_FOR\_CHECKMULTISIG = 20

Number of [public keys](key.md) allowed for [OP_CHECKMULTISIG](opcode.md).

#### MAX\_OPS\_PER\_SCRIPT = 201

Maximum number of [operations](opcode.md) allowed per [script](script.md) (excluding pushdata operations and OP_*N*).
Multisig operation additionally increases count by a number of pubkeys.


Soft Rules
----------

Can bend these without becoming incompatible with everyone.

#### MAX\_INV\_SZ = 50000

The maximum number of entries in an 'inv' protocol message.

#### MAX\_BLOCK\_SIZE\_GEN = MAX\_BLOCK\_SIZE / 2

The maximum size for mined blocks.

#### MAX\_STANDARD\_TX\_SIZE = MAX\_BLOCK\_SIZE\_GEN / 5

The maximum size for transactions we're willing to relay/mine.
