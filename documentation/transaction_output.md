[Index](index.md)

BTC::TransactionOutput
======================

Transaction Output (aka "txout") is a part of a bitcoin [transaction](transaction.md) that specifies
destination of the bitcoins being transferred.

Every output has `value` (in satoshis) and `script` (that typically corresponds to an [address](address.md)).

This class is frequently used to specify **unspent outputs** (aka "unspents"). 
Unspent outputs typically have optional attributes `transaction_hash` and `index` to allow
creating a corresponding [input](transaction_input.md).

Initializers
------------

#### new(data: *String*)

Returns a new transaction output initialized with a binary string in [wire format](wire_format.md).
Raises `ArgumentError` if transaction output is incomplete or incorrectly encoded.

#### new(stream: *IO*)

Returns a new transaction output initialized with data in [wire format](wire_format.md) read from a given stream.
Raises `ArgumentError` if transaction output is incomplete or incorrectly encoded.

#### new(*attributes*)

Returns a new transaction output with named [attributes](#attributes).
All attributes are optional and have appropriate default values.

```ruby
TransactionOutput.new(
  value: 42 * BTC::COIN,
  script: Address.parse("1CBtcGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG").script,
  ...
)
```

Attributes
----------

#### value

Amount in satoshis to be locked in this output.

#### script

An instance of [BTC::Script](script.md) that specifies conditions that allow spending bitcoins.

Typically corresponds to a recipient [address](address.md):

```ruby
Address.parse("1CBtcGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG").script
```

Optional Attributes
-------------------

These are not derived from transaction outputs’s binary data, but set from some other source.

#### transaction

Reference to the owning transaction. It is set on [tx.add_output](transaction.md#add_outputoutput) and
reset to `nil` in [tx.remove_all_outputs](transaction.md#remove_all_outputs). Default value is `nil`.

#### transaction_hash

Binary hash of the containing transaction. Default value is `nil`.

#### transaction_id

Hex big-endian hash of the containing transaction. See [Hash↔ID Conversion](hash_id.md).

#### index

Index of this output in the containing transaction. Default value is `nil`.

#### block_hash

Binary hash of the block at which containing transaction was included.
If not confirmed or not available, equals `nil`.

#### block_id

Hex big-endian hash corresponding to `block_hash`. See [Hash↔ID Conversion](hash_id.md).

#### block_height

Height of the block at which containing transaction was included.
If not confirmed equals `-1`.

Note: `block_height` might not be provided by some APIs while `confirmations` may be.
Default value is derived from `transaction` if possible or equals `nil`.

#### block_time

Time of the block at which containing transaction was included (`Time` instance or `nil`).
Default value is derived from `transaction` if possible or equals `nil`.

#### confirmations

Number of confirmations. Default value is derived from `transaction` if possible or equals `nil`.

#### spent

If available, returns whether this output is spent (`true` or `false`).
Default is `nil`. See also `spent_confirmations`.

#### spent_confirmations

If the containing transaction is spent, contains number of confirmations of the spending transaction.

Returns `nil` if not available or output is not spent.

Returns `0` if spending transaction is not confirmed.


Instance Methods
----------------

#### data

Binary representation of the transaction output in [wire format](wire_format.md) (aka payload).

#### dictionary

Dictionary representation of transaction output ready to be encoded in JSON, PropertyList etc.

