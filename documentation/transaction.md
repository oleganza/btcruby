[Index](index.md)

BTC::Transaction
================

**Transaction** (aka "tx") is an object that represents transfer of bitcoins 
from one or more [inputs](transaction_input.md) to one or more [outputs](transaction_output.md). 
Use `BTC::Transaction` class to inspect transactions or create them transactions manually. 
To build transaction we recommend using [BTC::TransactionBuilder](transaction_builder.md),
which takes care of a lot of difficulties and exposes easy to use, yet powerful enough API.

Transactions are stored within [blocks](block.md) that form the *block chain*.

The first transaction in a [block](block.md) is called *coinbase transaction*.
It has no inputs and the outputs contain collected mining fees and the mining reward (25 BTC per block as of March 2015).

Constants
---------

#### CURRENT_VERSION

Current version for all transactions. Equals `1`. 

#### DEFAULT\_FEE\_RATE

Default mining fee rate in satoshis per 1000 bytes. Equals `10000`.


Initializers
------------

#### new(hex: *String*)

Returns a new transaction initialized with a hex-encoded string in [wire format](wire_format.md).
Raises `ArgumentError` if transaction is incomplete or incorrectly encoded.

#### new(data: *String*)

Returns a new transaction initialized with a binary string in [wire format](wire_format.md).
Raises `ArgumentError` if transaction is incomplete or incorrectly encoded.

#### new(stream: *IO*)

Returns a new transaction initialized with data in [wire format](wire_format.md) read from a given stream.
Raises `ArgumentError` if transaction is incomplete or incorrectly encoded.

#### new(*attributes*)

Returns a new transaction with named [attributes](#attributes).
All attributes are optional and have appropriate default values.

```ruby
Transaction.new(
  version: 1,
  inputs: [...],
  outputs: [...],
  lock_time: 0,
  block_height: 319238,
  ...
)
```

Attributes
----------

#### version

Version of the transaction. Default value is `BTC::Transaction::CURRENT_VERSION`.

#### inputs

List of [TransactionInput](transaction_input.md) objects. See also `add_input` and `remove_all_inputs`.

#### outputs

List of [TransactionOutput](transaction_output.md) objects. See also `add_output` and `remove_all_outputs`.

#### lock_time

Lock time makes transaction not spendable until a designated time in the future.
Contains either a block height or a unix timestamp.
If this value is below [LOCKTIME_THRESHOLD](constants.md),
then it is treated as a block height. Default value is `0`.

Optional Attributes
-------------------

These are not derived from transaction binary data, but set from some other source.

#### block_hash

Binary hash of the block at which transaction was included.
If not confirmed or not available, equals `nil`.

Read-write. Default value is `nil`.

#### block_id

Hex big-endian hash of the block at which transaction was included.
See [Hash↔ID Conversion](hash_id.md).
If not confirmed or not available, equals `nil`.

Read-write. Default value is `nil`.

#### block_height

Height of the block at which transaction was included. If not confirmed equals `-1`.
Note: `block_height` might not be provided by some APIs while `confirmations` may be.

Read-write. Default value is `nil`.

#### block_time

Time of the block at which tx was included (`Time` instance or `nil`).

Read-write. Default value is `nil`.

#### confirmations

Number of confirmations for this transaction (depth in the blockchan).
Value `0` stands for unconfirmed transaction (stored in mempool). 

Read-write. Default value is `nil`.

#### fee

If available, returns mining fee paid by this transaction.
If set, `inputs_amount` is updated as (`outputs_amount` + `fee`).

Read-write. Default value is `nil`.

#### inputs_amount

If available, returns total amount of all inputs.
If set, `fee` is updated as (`inputs_amount` - `outputs_amount`).

Read-write. Default value is `nil`.

#### outputs_amount

Total amount on all outputs (not including fees).
Always available because [outputs](transaction_output.md) contain their amounts.

Read-only.


Instance Methods
----------------

#### transaction_hash

32-byte transaction hash identifying the transaction.

#### transaction_id

Hex big-endian hash of the transaction. See [Hash↔ID Conversion](hash_id.md).

#### data

Binary representation of the transaction in [wire format](wire_format.md) (aka payload).

#### dictionary

Dictionary representation of transaction ready to be encoded in JSON, PropertyList etc.

#### coinbase?

Returns `true` if this transaction generates new coins.

#### signature\_hash(input\_index: *Integer*, output\_script: *BTC::Script*, hash\_type: *Integer*)

Returns a binary hash for signing a transaction (see [BTC::Key#ecdsa_signature](key.md#ecdsa_signaturehash)).
You should specify an input index, output [script](script.md) of the previous transaction for that input,
and an optional [hash type](signature.md) (default is `SIGHASH_ALL`).

#### to_s

Returns a hex representation of the transaction `data`.

#### to_hex

Returns a hex representation of the transaction `data`.

#### dup

Returns a complete copy of a transaction (each input and output is also copied via `dup`).

#### ==

Returns `true` if both transactions have equal binary representation.

#### add_input(*input*)

Adds a [BTC::TransactionInput](transaction_input.md) instance to a list of `inputs`.
After being added, input will have its `transaction` attribute set to the receiver.

Returns `self`.

#### add_output(*output*)

Adds a [BTC::TransactionOutput](transaction_output.md) instance to a list of `outputs`.
After being added, output will have its `transaction` attribute set to the receiver.

Returns `self`.

#### remove\_all\_inputs

Removes all [inputs](transaction_input.md) from the transaction and returns `self`.

#### remove\_all\_outputs

Removes all [outputs](transaction_output.md) from the transaction and returns `self`.

