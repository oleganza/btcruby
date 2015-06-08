[Index](index.md)

BTC::TransactionBuilder
=======================

Transaction Builder allows building complex transactions in a convenient and safe manner.
It handles logic of selecting unspent outputs, calculates mining fees and computes amount for the change output.

Example
-------

```ruby
# 0. Create an instance of TransactionBuilder.
builder = TransactionBuilder.new

# 1. Provide a list of addresses or WIF objects to get unspent outputs from.
builder.input_addresses = [ "L1uyy5qTuGrVXrmrsvHWHgVzW9kKdrp27wBC7Vs6nZDTF2BRUVwy" ]

# 2. Use a local UTXO index or Chain.com API to fetch unspent outputs for the input addresses.
builder.unspent_outputs_provider_block = lambda do |addresses, outputs_amount, outputs_size, fee_rate|
  return array of BTC::TransactionOutput instances...
end

# 3. Specify payment address and amount
builder.outputs = [ 
  TransactionOutput.new(value: 10_000, script: Address.parse("17XBj6iFEsf8kzDMGQk5ghZipxX49VXuaV").script) 
]

# 4. Specify the change address
builder.change_address = Address.parse("1CBtcGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG")

# 5. Build the transaction and broadcast it.
result = builder.build
tx = result.transaction
puts tx.to_hex

# => 01000000018689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e11
#    000000006b483045022100e280f71106a84a4a1b1a2035eae70266eb53630beab2b59cc...
```

Result Attributes
-----------------

Transaction Builder's `build` method returns `BTC::TransactionBuilderResult` instance with the following attributes:

#### transaction

[BTC::Transaction](transaction.md) instance. Each input is either signed (if WIF was used)
or contains an unspent output's script as its signature_script.

Unsigned inputs are marked using `unsigned_input_indexes` attribute.

#### unsigned\_input\_indexes

List of input indexes that are not signed.
Empty list means all indexes are signed.

#### fee

Total fee for the composed transaction.
Equals `inputs_amount` - `outputs_amount`.

#### inputs_amount

Total amount on the inputs.

#### outputs_amount

Total amount on the outputs.

#### change_amount

Amount in satoshis sent to a change address.
Equals `outputs_amount` - `sent_amount`.

#### sent_amount

Amount in satoshis sent to outputs specified by the user.
Equals `outputs_amount` - `change_amount`.


Attributes
----------

#### input_addresses

Addresses from which to fetch the inputs. Could be base58-encoded addresses or [WIF](wif.md) strings, or [BTC::Address](address.md) instances.

If any address is a WIF (string or `BTC::WIF` instance), the corresponding input will be
automatically signed with its private key using `SIGHASH_ALL` [hashtype](signature.md).

Otherwise, the `signature_script` in the input will be set to the output script from unspent output and index of that input will be added to `unsigned_input_indexes`.

#### unspent_outputs

Actual available [BTC::TransactionOutputs](transaction_output.md) to spend.
If not specified, builder will fetch and remember unspent outputs
using `unspent_outputs_provider_block`.
Only necessary inputs will be selected for spending.

If [TransactionOutput#confirmations](transaction_output.md#confirmations) attribute is not `nil`, outputs are sorted
from oldest to newest, unless `keep_unspent_outputs_order` is set to `true`.

#### unspent\_outputs\_provider\_block

Data-providing block with signature lambda{|addresses, outputs_amount, outputs_size, fee_rate|  [...] }

* `addresses` is a list of BTC::Address instances.
* `outputs_amount` is a total amount in satoshis to be spent in all outputs (not including change output).
* `outputs_size` is a total size of all outputs in bytes (including change output).
* `fee_rate` is a miner's fee per 1000 bytes.

Block returns an array of unspent BTC::TransactionOutput instances with non-nil #transaction_hash and #index.

Note: data provider may or may not use additional parameters as a hint
to select the best matching unspent outputs. If it takes into account these parameters,
it is responsible to provide enough unspent outputs to cover the resulting fee.

If `outputs_amount` is 0, all possible unspent outputs are expected to be returned.

#### outputs

An array of `BTC::TransactionOutput` instances determining how many coins to spend and how.
If the array is empty, all unspent outputs are spent to the change address.

#### change_address

Change address (base58-encoded string or `BTC::Address`).
Must be specified, but may not be used if change is too small.

#### fee_rate

Miner's fee per kilobyte (1000 bytes).
Default is `BTC::Transaction::DEFAULT_FEE_RATE`.

#### minimum_change

Minimum amount of change below which transaction is not composed.
If change amount is non-zero and below this value, more unspent outputs are used.
If change amount is zero, change output is not even created and this attribute is not used.
Default value equals `fee_rate`.

#### dust_change

Amount of change that can be forgone as a mining fee if there are no more
unspent outputs available. If equals zero, no amount is allowed to be forgone.

Default value equals `minimum_change`. This means builder will never fail with "insufficient funds" just because it could not
find enough unspents for big enough change. In worst case it will forgo the change
as a part of the mining fee. Set to 0 to avoid wasting a single satoshi.

#### keep\_unspent\_outputs\_order

If true, does not sort `unspent_outputs` by confirmations number.
Default is `false`, but order will be preserved if `confirmations` attribute is `nil`.


Instance Method
---------------

#### build

Attempts to build a transaction and returns an instance of `BTC::TransactionBuilderResult`. 

Raises a subclass of `TransactionBuilderError` exception.

Errors
------

#### TransactionBuilderError < BTCError

A base class for all errors used by Transaction Builder.

#### TransactionBuilderMissingChangeAddressError < TransactionBuilderError

Change address is not specified.

#### TransactionBuilderMissingUnspentOutputsError < TransactionBuilderError

Unspent outputs are missing. Maybe because input_addresses are not specified.

#### TransactionBuilderInsufficientFundsError < TransactionBuilderError

Unspent outputs are not sufficient to build the transaction.




