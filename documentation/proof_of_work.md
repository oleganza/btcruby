[Index](index.md)

BTC::ProofOfWork
================

ProofOfWork module defines functions to convert between different kinds of difficulty and proof of work representations.

* **Target** is big unsigned integer derived from 256-bit hash (interpreted as little-endian integer).
Hash of a valid block should be below target.
* **Bits** is a "compact" representation of a target as uint32.
* **difficulty** is a floating point multiple of the minimum difficulty.
Difficulty = 2 means the block is 2x more difficult than the minimal difficulty.

You can use all functions as methods on `ProofOfWork` object.

Constants
---------

#### MAX\_TARGET\_MAINNET

Defines the minimum difficulty for the proof of work on mainnet blockchain. See also [Network#max_target](network.md#max_target).

Equals `0x00000000ffff0000000000000000000000000000000000000000000000000000`.

#### MAX\_TARGET\_TESTNET

Defines the minimum difficulty for the proof of work on testnet blockchain. See also [Network#max_target](network.md#max_target).

Equals `0x00000007fff80000000000000000000000000000000000000000000000000000`.


Module Functions
----------------

#### bits\_from\_target(*target*)

Converts a 256-bit integer (*Bignum*) to 32-bit compact representation (*Fixnum*).

```ruby
>> ProofOfWork.bits_from_target(0x00000000ffff0000000000000000000000000000000000000000000000000000)
=> 0x1d00ffff
```

#### target\_from\_bits(*bits*)

Converts a 32-bit compact representation of the target to a 256-bit integer (*Bignum*).

```ruby
>> ProofOfWork.target_from_bits(0x1d00ffff)
=> 0x00000000ffff0000000000000000000000000000000000000000000000000000
```

#### bits\_from\_difficulty(*difficulty*, max\_target: MAX\_TARGET\_MAINNET)

Computes bits from difficulty. Could be inaccurate since difficulty is a limited-precision floating-point number.

If not specified, `max_target` equals `MAX_TARGET_MAINNET`.

#### difficulty\_from\_bits(*bits*, max\_target: MAX\_TARGET\_MAINNET)

Computes difficulty from bits.

If not specified, `max_target` equals `MAX_TARGET_MAINNET`.

#### target\_from\_difficulty(*difficulty*, max\_target: MAX\_TARGET\_MAINNET)

Computes target from difficulty. Could be inaccurate since difficulty is a limited-precision floating-point number.

If not specified, `max_target` equals `MAX_TARGET_MAINNET`.

#### difficulty\_from\_target(*target*, max\_target: MAX\_TARGET\_MAINNET)

Compute relative difficulty from a given target.
E.g. returns 2.5 if target is 2.5 times harder to reach than the `max_target`.

If not specified, `max_target` equals `MAX_TARGET_MAINNET`.

#### hash\_from\_target(*target*)

Converts target integer to a binary little-endian 32-byte string padded with zero bytes.

#### target\_from\_hash(*hash*)

Converts 32-byte binary string to a target integer (`hash` is treated as a little-endian integer).
