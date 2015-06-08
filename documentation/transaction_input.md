[Index](index.md)

BTC::TransactionInput
=====================

Transaction Input (aka "txin") is a part of a bitcoin [transaction](transaction.md) that
unlocks bitcoins stored in the [outputs](transaction_output.md) of the previous transactions.

Every input contains a reference to some output (transaction hash and a numeric index of the output)
and a [signature script](script.md) that typically contains [signatures](key.md) and other data
to satisfy conditions defined by the corresponding output script.

Constants
---------

#### INVALID_INDEX

Invalid index is used in *coinbase* inputs. Equals `0xFFFFFFFF` (`(unsigned int) -1`).

#### MAX_SEQUENCE

Equals `0xFFFFFFFF`.

#### ZERO_HASH256

Equals all-zero 32-byte binary string.


Initializers
------------

#### new(data: *String*)

Returns a new transaction input initialized with a binary string in [wire format](wire_format.md).
Raises `ArgumentError` if transaction input is incomplete or incorrectly encoded.

#### new(stream: *IO*)

Returns a new transaction input initialized with data in [wire format](wire_format.md) read from a given stream.
Raises `ArgumentError` if transaction input is incomplete or incorrectly encoded.

#### new(*attributes*)

Returns a new transaction input with named [attributes](#attributes).
All attributes are optional and have appropriate default values.

```ruby
TransactionInput.new(
  previous_id: "d21633ba23f70118185227be58a63527675641ad37967e2aa461559f577aec43",
  previous_index: 0,
  signature_script: Script.new << script_signature << pubkey,
  ...
)
```

Attributes
----------

#### previous_hash

Binary hash of the previous transaction.

#### previous_id

Hex big-endian hash of the previous transaction. See [Hash↔ID Conversion](hash_id.md).

#### previous_index

Index of the previous transaction's output (uint32).
Default value is `INVALID_INDEX`.

#### signature_script

[BTC::Script](script.md) instance that proves ownership of the previous transaction output.
We intentionally do not call it "script" to avoid accidental confusion with
[TransactionOutput#script](transaction_output.md#script).

For *coinase* inputs use `coinbase_data` instead.

#### coinbase_data

Binary string contained in place of `signature_script` in a coinbase input (see `coinbase?`).

Returns `nil` if it is not a coinbase input.

#### sequence

Input sequence (uint32_t). Default is maximum value 0xFFFFFFFF.
Sequence is used to update a timelocked tx stored in memory of the nodes. It is only relevant when tx lock_time > 0.
Currently, for DoS and security reasons, nodes do not store timelocked transactions making the sequence number meaningless.


Optional Attributes
-------------------

These are not derived from transaction input’s binary data, but set from some other source.

#### transaction

Optional reference to the owning transaction. It is set on [tx.add_input](transaction.md#add_inputinput) and
reset to `nil` on [tx.remove_all_inputs](transaction.md#remove_all_inputs).

Default value is `nil`.

#### transaction_output

Optional reference to an [output](transaction_output.md) that this input is spending.

#### value

Optional value in the corresponding output (in satoshis).

Default value is `transaction_output.value` or `nil`.


Instance Methods
----------------

#### data

Binary representation of the transaction input in [wire format](wire_format.md) (aka payload).

#### dictionary

Dictionary representation of transaction input ready to be encoded in JSON, PropertyList etc.

#### coinbase?

Returns `true` if this transaction input belongs to a *coinbase* transaction.
Coinbase input has no `signature_script` and its `index` equals `INVALID_INDEX`.



