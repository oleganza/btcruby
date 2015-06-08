[Index](index.md)

BTC::Script
===========

Script is a string of [opcodes](opcode.md) specifying conditions that allow moving bitcoins from one transaction to another.

Script can be used in two contexts:

* In [transaction outputs](transaction_output.md), as a predicate (e.g. “only an owner of this key is allowed to spend funds”).
Such script is called simply a **script** or a **scriptPubKey**.
* In [transaction inputs](transaction_input.md), as an input to a script from a corresponding output
(e.g. “here is a signature made with the key mentioned in the output”).
Such script is called a **signature script** or a **scriptSig**.

Typically an output script contains interesting opcodes while the input script contains only static data, without any opcodes
(because any operations in the input script can be always pre-computed).

In case of [P2SH](p2sh.md) payments, the output script contains only a hash of an actual predicate script.
The input script then contains both the static data and a corresponding predicate script (called "redemption script").


Initializers
------------

#### new()

Returns a new empty `BTC::Script` instance. Use `<<` or `+` operators to add operators to the script.

```ruby
>> Script.new << OP_9 << "some pushdata operation" << OP_VERIFY
=> OP_9 736f6d65207075736864617461206f7065726174696f6e OP_VERIFY
```

#### new(hex: *String*)

Returns a new `BTC::Script` instance deserialized from a given hex-encoded string.

```ruby
>> Script.new(hex: "76a914f2b27f7f9e519a6e77228a603c5c9a8434946a2288ac")
=> OP_DUP OP_HASH160 f2b27f7f9e519a6e77228a603c5c9a8434946a22 OP_EQUALVERIFY OP_CHECKSIG
```

#### new(data: *String*)

Returns a new `BTC::Script` instance deserialized from a given binary string.

```ruby
>> Script.new(data: "76a914f2b27f7f9e519a6e77228a603c5c9a8434946a2288ac".from_hex)
=> OP_DUP OP_HASH160 f2b27f7f9e519a6e77228a603c5c9a8434946a22 OP_EQUALVERIFY OP_CHECKSIG
```

#### new(op\_return: *String* or *Array of Strings*)

Returns a new `BTC::Script` instance containing `OP_RETURN` opcode followed by one or more *pushdata* binary strings.

```ruby
>> Script.new(op_return: "correct horse battery staple")
=> OP_RETURN 636f727265637420686f727365206261747465727920737461706c65

>> Script.new(op_return: ["correct horse battery", "battery staple correct"])
=> OP_RETURN 636f727265... 6261747465...
```

#### new(public\_keys: *Array*, signatures\_required: *Integer*)

Returns a new `BTC::Script` instance containing an `OP_CHECKMULTISIG` opcode with the provided public keys and a required number of signatures:

```ruby
>> a, b, c = [1,2,3].map{ Key.random.public_key }
>> Script.new(public_keys: [a, b, c], signatures_required: 2)
=> OP_2 0357f93e... 025f3ed5... 021a90c5... OP_3 OP_CHECKMULTISIG
```


Instance Methods
----------------

#### data

Returns a serialized binary form of the script.

#### standard?

Returns `true` if this script is of standard kind. Valid non-standard scripts are allowed,
but are not relayed by nodes with default configuration and may take longer to be included in a block.

As of March 2015, scripts returning `true` from the following methods are considered standard:

* `public_key_hash_script?`
* `script_hash_script?`
* `standard_multisig_script?`
* `public_key_script?`
* `standard_op_return_script?`

#### data_only?

Returns `true` if the script consists of *pushdata* operations only (uncluding small integer opcodes: `OP_0`, `OP_1` etc).
This is used to verify input script for [P2SH](p2sh.md) output.

#### to_s

Returns a human-readable representation of script. E.g. instead of raw binary `76a914f2b2...` returns `"OP_DUP OP_HASH160 f2b2..."`.

#### to_a

Returns an array of [opcodes](opcode.md) (integers) and *pushdatas* (strings). `OP_0` is encoded as an empty string.

#### to_hex

Returns a raw binary representation of script (see `data`) in hex encoding.

#### dup

Returns a complete copy of a script.

#### ==

Returns true if both scripts can be serialized in the same binary string.



### Regular Scripts


#### public\_key\_script?

Returns `true` if the script is of form `<pubkey> OP_CHECKSIG` (rarely used pay-to-pubkey script).
  
#### public_key

Returns a raw public key if this script is `public_key_script?`.
  
#### public\_key\_hash\_script?

Returns `true` if this script is a [P2PKH](p2pkh.md) script (`OP_DUP OP_HASH160 <20-byte hash> OP_EQUALVERIFY OP_CHECKSIG`).
This is the most used kind of script that corresponds to a [pay-to-pubkey-hash](p2pkh.md) address.

#### public\_key\_hash

Returns a 20-byte hash of the public key if this script is `public_key_hash_script?`.

#### script\_hash\_script?

Returns `true` if this script is a [P2SH](p2sh.md) script (`OP_HASH160 <20-byte hash> OP_EQUAL`).

#### script_hash

Returns a 20-byte hash of the script if this script is `script_hash_script?`.



### Null Data (OP_RETURN) Scripts

#### op\_return\_script?

Returns `true` if this script contains `OP_RETURN` opcode followed by pushdata.

#### standard\_op\_return\_script?

Returns `true` if this script contains `OP_RETURN` opcode followed by one pushdata string with a length of 40 bytes or less.

#### op\_return\_data

Returns the first *pushdata* string if this script is `op_return_script?`.

#### op\_return\_items

Returns all *pushdata* strings if this script is `op_return_script?`.




### Multisig Scripts

#### multisig\_script?

Returns `true` if this script is a valid multisig script of form `<M> <public keys> <N> OP_CHECKMULTISIG` where:
  
* Both N and M are greater than zero
* N is greater or equal M
* N equals the number of public keys.

Both *N* and *M* can be encoded as small integer [opcodes](opcode.md) (`OP_1` to `OP_16`) or as *pushdatas* containing little-endian integers.

#### standard\_multisig\_script?

Returns `true` if this script is a multisig script with additional constraints:

* Both *N* and *M* are encoded as small integer opcodes (`OP_1`, `OP_2` etc.)
* Both *N* and *M* are not greater than 15.

Note: this applies to multisig scripts used as *redeem scripts* within [P2SH](p2sh.md).
Standard bare multisig scripts (not wrapped in P2SH) must have *N* no greater than 3.

#### multisig\_public\_keys

Returns an array of raw public keys if this script is `multisig_script?`.

#### multisig\_signatures\_required

Returns a number of required signatures if this script is `multisig_script?`.



### Conversion

#### standard_address(network: *BTC::Network*)

Returns [BTC::PublicKeyAddress](p2pkh.md) or [BTC::ScriptHashAddress](p2sh.md) if
the script is a standard output script for these addresses.
Returns `nil` for all other scripts.

If `network` is not specified, [BTC::Network.default](network.md#default) is used.

#### p2sh_script

Returns a [P2SH](p2sh.md) script that wraps the receiver: `OP_HASH160 #{script.data.hash160} OP_EQUAL`.

#### simulated\_signature\_script(strict: true|false)

Returns a dummy *signature script* of the same length and structure as the intended *signature script* for the receiver. 
Only a few standard script types are supported.

Set `strict` to `false` to allow imprecise guess for P2SH script (2-of-3 multisig). Default is `true`.

Returns `nil` if could not determine a matching script.




### Modification


#### append_opcode(opcode)

Appends a non-pushdata opcode to the script.

#### append_pushdata(string, opcode: *Integer*)

Appends a pushdata opcode with binary `string` in the most compact encoding.

Optional `opcode` may be equal to `OP_PUSHDATA1`, `OP_PUSHDATA2`, or `OP_PUSHDATA4` to specify a non-compact encoding.

Raises `ArgumentError` if opcode does not represent a given string length.

#### delete_opcode(opcode)

Removes all occurences of the `opcode`. Typically used by verification engine to remove `OP_CODESEPARATOR`.

#### delete_pushdata(string)

Removes all occurences of *pushdata* opcodes containing `string`.

#### append_script(script)

Appends a `BTC::Script` instance to receiver.

#### <<(*script*)

Appends `BTC::Script` instance to receiver. Same as `append_script(script)`.

#### <<(*Integer*)

Appends an opcode specified by the *Integer*. Same as `append_opcode(integer)`.

#### <<(*String*)

Appends a *pushdata* opcode with a given string. Same as `append_pushdata(string)`.

#### <<(*Array*)

Appends an array of `BTC::Script` instances, opcode and strings. Array may contain nested arrays.

#### +

Returns a copy of the receiver with appended object using `<<`. It is defined as `self.dup << argument`.



