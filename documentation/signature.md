[Index](index.md)

Bitcoin Signatures
==================

Bitcoin uses ECDSA signatures that prove that an owner of a certain [private key](key.md#private_key) 
acknowledges a certain message (usually a [transaction](transaction.md)).

One or more signatures are used in a [transaction input](transaction_input.md) to prove that
the owner of bitcoins locked in a corresponding [output](transaction_output.md) allows spending them in this specific transaction.

Within Bitcoin transactions, signature contains an extra byte (*hash type*) that specifies how exactly the transaction must be transformed before being signed.
To differentiate between regular signatures and signatures with a hash type, we use the following terms:

**Signature** is a DER-encoded ECDSA signature.

**Script Signature** is a DER-encoded ECDSA signature with an appended *hashtype* byte.

Hash Types
----------

Hash type determines how [OP_CHECKSIG](opcode.md#op_checksig) hashes the [transaction](transaction.md)
to verify the signature in a [transaction input](transaction_output.md).
Depending on hash type, transaction is modified in some way before its hash is computed.
Hash type is 1 byte appended to a signature in a [transaction input](transaction_input.md).

First three types are mutually exclusive (tested using `hashtype & 0x1F`).
`SIGHASH_ANYONECANPAY` type can be combined together with any of the first three types.

#### BTC::SIGHASH_ALL = 0x01

Default. Signs all inputs and outputs.
Other inputs have scripts and sequences zeroed out, current input has its script
replaced by the previous transaction's output script (or, in case of [P2SH](p2sh.md),
by the signatures and the redemption script).

If `(hashtype & SIGHASH_OUTPUT_MASK)` is not `SIGHASH_NONE` or `SIGHASH_SINGLE`, then `SIGHASH_ALL` is used.

#### BTC::SIGHASH_NONE = 0x02

All outputs are removed. "I don't care where it goes as long as others pay".
Note: this is not safe when used with `SIGHASH_ANYONECANPAY`, because then anyone who relays the transaction
can pick your input and use in his own transaction.
It's also not safe if all inputs are `SIGHASH_NONE` as well (or it's the only input).

#### BTC::SIGHASH_SINGLE = 0x03

Hash only the output with the same index as the current input.
Preceding outputs are "nullified", other outputs are removed.
Special case: if there is no matching output, hash is equal
`0000000000000000000000000000000000000000000000000000000000000001` (32 bytes)

#### BTC::SIGHASH\_OUTPUT\_MASK = 0x1F

This mask is used to determine one of the first types independently from `SIGHASH_ANYONECANPAY` option:

```
if (hashtype & SIGHASH_OUTPUT_MASK) == SIGHASH_NONE
  blank all outputs
end
```

#### BTC::SIGHASH_ANYONECANPAY = 0x80

Removes all inputs except for current txin before hashing.
This allows to sign the transaction outputs without knowing who and how adds other inputs.
E.g. a crowdfunding transaction with 100 BTC output can be signed independently by any number of people
and will become valid only when someone combines all inputs in a single transaction to make it valid.
Can be used together with any of the above types.


