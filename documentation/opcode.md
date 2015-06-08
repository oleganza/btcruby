[Index](index.md)

BTC::Opcode
===========

**Operator** is a basic building block of the [script](script.md).
It is a one-byte command (*opcode*) that performs a certain action during script evaluation.
Module `BTC::Opcode` defines all available opcodes and conversion methods.

There are two kinds of opcodes:

* **Pushdata** — an opcode that pushes arbitrary data on stack.
All opcodes with value less or equal `OP_PUSHDATA4` are *pushdata* opcodes (this includes `OP_0`, but does not include `OP_1`, `OP_2` etc.)
* **Operation** — an opcode that performs some operation. This includes integer-pushing opcodes starting with `OP_1`.

Module Functions
----------------

#### name\_for\_opcode(opcode)

Returns a name for a given opcode value. For unknwon opcode returns `"OP_UNKNOWN"`

```ruby
Opcode.name_for_opcode(OP_VERIFY) # => "OP_VERIFY"
```

#### opcode\_for\_name(name)

Returns an opcode value for a given name. For unknwon names returns `OP_INVALIDOPCODE` (0xFF).

```ruby
Opcode.opcode_for_name("OP_VERIFY") # => OP_VERIFY
```

#### opcode\_for\_small\_integer(int)

Returns an opcode corresponding to a small integer (-1, 0, 1, ... 16).
For invalid integer returns `OP_INVALIDOPCODE`.

```ruby
Opcode.opcode_for_small_integer(-1) # => OP_1NEGATE
```

#### small\_integer\_from\_opcode(opcode)

Returns a small integer (-1, 0, 1, ... 16) corresponding to a given opcode.
For invalid integer returns `nil`.

```ruby
Opcode.small_integer_from_opcode(OP_16) # => 16
```


Operators
---------

### 1. Operators pushing data on stack

Name            | Value       |  Description
:---------------|:------------|:-----------------------------------
OP_FALSE        | 0x00        | Pushes byte `0` on the stack.
OP_0            | 0x00        | Pushes byte `0` on the stack.
OP_PUSHDATA*N*  | 0x01..0x4b  | Any opcode with value < `OP_PUSHDATA1` is a length of the string to be pushed on the stack. So opcode 0x01 is followed by 1 byte of data, 0x09 by 9 bytes and so on up to 0x4b (75 bytes).
OP_PUSHDATA1    | 0x4c        | Followed by a 1-byte length of the string to push (allows pushing 0..255 bytes).
OP_PUSHDATA2    | 0x4d        | Followed by a 2-byte length of the string to push (allows pushing 0..65535 bytes).
OP_PUSHDATA4    | 0x4e        | Followed by a 4-byte length of the string to push (allows pushing 0..4294967295 bytes).
OP_1NEGATE      | 0x4f        | Pushes number `-1` on the stack.
OP_RESERVED     | 0x50        | Not assigned. If executed, transaction is invalid.
OP_TRUE         | 0x51        | Pushes number `1` on the stack.
OP_1            | 0x51        | Pushes number `1` on the stack.
OP_2            | 0x52        | Pushes number `2` on the stack.
OP_3            | 0x53        | Pushes number `3` on the stack.
OP_4            | 0x54        | Pushes number `4` on the stack.
OP_5            | 0x55        | Pushes number `5` on the stack.
OP_6            | 0x56        | Pushes number `6` on the stack.
OP_7            | 0x57        | Pushes number `7` on the stack.
OP_8            | 0x58        | Pushes number `8` on the stack.
OP_9            | 0x59        | Pushes number `9` on the stack.
OP_10           | 0x5a        | Pushes number `10` on the stack.
OP_11           | 0x5b        | Pushes number `11` on the stack.
OP_12           | 0x5c        | Pushes number `12` on the stack.
OP_13           | 0x5d        | Pushes number `13` on the stack.
OP_14           | 0x5e        | Pushes number `14` on the stack.
OP_15           | 0x5f        | Pushes number `15` on the stack.
OP_16           | 0x60        | Pushes number `16` on the stack.


### 2. Control Flow Operators

Bitcoin executes all operators from `OP_IF` to `OP_ENDIF` even inside "non-executed" branch (to keep track of nesting).
Since `OP_VERIF` and `OP_VERNOTIF` are not assigned, even inside a non-executed branch they will fall in "default:" switch case
and cause the script to fail. Some other operators like `OP_VER` can be present inside non-executed branch because they'll be skipped.

Name            | Value       |  Description
:---------------|:------------|:-----------------------------------
OP_NOP          | 0x61        | Does nothing.
OP_VER          | 0x62        | Not assigned. If executed, transaction is invalid.
OP_IF           | 0x63        | If the top stack value is not 0, the statements are executed. The top stack value is removed.
OP_NOTIF        | 0x64        | If the top stack value is 0, the statements are executed. The top stack value is removed.
OP_VERIF        | 0x65        | Not assigned. Script is invalid with that opcode (even if inside non-executed branch).
OP_VERNOTIF     | 0x66        | Not assigned. Script is invalid with that opcode (even if inside non-executed branch).
OP_ELSE         | 0x67        | Executes code if the previous `OP_IF` or `OP_NOTIF` was not executed.
OP_ENDIF        | 0x68        | Finishes if/else block.
OP_VERIFY       | 0x69        | Removes item from the stack if it's not 0x00 or 0x80 (negative zero). Otherwise, marks script as invalid.
OP_RETURN       | 0x6a        | Marks transaction as invalid.

### 3. Stack Operators

Name            | Value       |  Description
:---------------|:------------|:-----------------------------------
OP_TOALTSTACK   | 0x6b        | Moves item from the stack to altstack.
OP_FROMALTSTACK | 0x6c        | Moves item from the altstack to stack.
OP_2DROP        | 0x6d        | Removes top 2 items from stack. Fails if less than 2 items are available.
OP_2DUP         | 0x6e        | (a b → a b a b)
OP_3DUP         | 0x6f        | (a b c → a b c a b c)
OP_2OVER        | 0x70        | (a b c d → a b c d a b) 
OP_2ROT         | 0x71        | (a b c d e f → c d e f a b)
OP_2SWAP        | 0x72        | (a b c d → c d a b)
OP_IFDUP        | 0x73        | Duplicates the top value only if it's not zero or negative zero (0x80).
OP_DEPTH        | 0x74        | Adds size of the stack as a signed little-endian integer on stack.
OP_DROP         | 0x75        | Removes the top value on stack.
OP_DUP          | 0x76        | Duplicates the top value.
OP_NIP          | 0x77        | Removes the value below the top one. Fails if less than 2 items are available.
OP_OVER         | 0x78        | (a b → a b a)
OP_PICK         | 0x79        | (x(n) ... x2 x1 x0 n → x(n) ... x2 x1 x0 x(n))
OP_ROLL         | 0x7a        | (x(n) ... x2 x1 x0 n → x(n-1) ... x2 x1 x0 x(n))
OP_ROT          | 0x7b        | (a b c → b c a)
OP_SWAP         | 0x7c        | (a b → b a)
OP_TUCK         | 0x7d        | (a b → b a b)


### 4. Splice Operators

Name            | Value       |  Description
:---------------|:------------|:-----------------------------------
OP_CAT          | 0x7e        | Disabled opcode. If executed, transaction is invalid.
OP_SUBSTR       | 0x7f        | Disabled opcode. If executed, transaction is invalid.
OP_LEFT         | 0x80        | Disabled opcode. If executed, transaction is invalid.
OP_RIGHT        | 0x81        | Disabled opcode. If executed, transaction is invalid.
OP_SIZE         | 0x82        | Adds byte length of the top item as a signed little-endian integer.


### 5. Logic Operators

Name            | Value       |  Description
:---------------|:------------|:-----------------------------------
OP_INVERT       | 0x83        | Disabled opcode. If executed, transaction is invalid.
OP_AND          | 0x84        | Disabled opcode. If executed, transaction is invalid.
OP_OR           | 0x85        | Disabled opcode. If executed, transaction is invalid.
OP_XOR          | 0x86        | Disabled opcode. If executed, transaction is invalid.
OP_EQUAL        | 0x87        | Last two items are removed from the stack and compared. Result (`true` or `false`) is pushed to the stack.
OP\_EQUALVERIFY | 0x88        | Same as `OP_EQUAL`, but removes the result from the stack if it's true or marks script as invalid.
OP_RESERVED1    | 0x89        | Disabled opcode. If executed, transaction is invalid.
OP_RESERVED2    | 0x8a        | Disabled opcode. If executed, transaction is invalid.

### 6. Numeric Operators

Name                  | Value |  Description
:---------------------|:------|:-----------------------------------
OP_1ADD               | 0x8b  | Adds 1 to last item, pops it from stack and pushes result.
OP_1SUB               | 0x8c  | Substracts 1 to last item, pops it from stack and pushes result.
OP_2MUL               | 0x8d  | Disabled opcode. If executed, transaction is invalid.
OP_2DIV               | 0x8e  | Disabled opcode. If executed, transaction is invalid.
OP_NEGATE             | 0x8f  | Negates the number, pops it from stack and pushes result.
OP_ABS                | 0x90  | Replaces number with its absolute value
OP_NOT                | 0x91  | Replaces number with True if it's zero, False otherwise.
OP_0NOTEQUAL          | 0x92  | Replaces number with True if it's not zero, False otherwise.
OP_ADD                | 0x93  | (x y → x+y)
OP_SUB                | 0x94  | (x y → x-y)
OP_MUL                | 0x95  | Disabled opcode. If executed, transaction is invalid.
OP_DIV                | 0x96  | Disabled opcode. If executed, transaction is invalid.
OP_MOD                | 0x97  | Disabled opcode. If executed, transaction is invalid.
OP_LSHIFT             | 0x98  | Disabled opcode. If executed, transaction is invalid.
OP_RSHIFT             | 0x99  | Disabled opcode. If executed, transaction is invalid.
OP_BOOLAND            | 0x9a  | (x y → x and y)
OP_BOOLOR             | 0x9b  | (x y → x or y)
OP_NUMEQUAL           | 0x9c  | (x y → x == y)
OP_NUMEQUALVERIFY     | 0x9d  | Same as `OP_NUMEQUAL OP_VERIFY`.
OP_NUMNOTEQUAL        | 0x9e  | (x y → x ≠ y)
OP_LESSTHAN           | 0x9f  | (x y → x < y)
OP_GREATERTHAN        | 0xa0  | (x y → x > y)
OP_LESSTHANOREQUAL    | 0xa1  | (x y → x ≤ y)
OP_GREATERTHANOREQUAL | 0xa2  | (x y → x ≥ y)
OP_MIN                | 0xa3  | (x y → min(x,y))
OP_MAX                | 0xa4  | (x y → max(x,y))
OP_WITHIN             | 0xa5  | (x min max → min ≤ x < max)

### 7. Crypto Operators


Name                   | Value       |  Description
:----------------------|:------------|:-----------------------------------
OP_RIPEMD160           | 0xa6        | Replaces top value with its [RIPEMD-160](http://en.wikipedia.org/wiki/RIPEMD) hash.
OP_SHA1                | 0xa7        | Replaces top value with its [SHA-1](http://en.wikipedia.org/wiki/SHA-1) hash.
OP_SHA256              | 0xa8        | Replaces top value with its [SHA-256](http://en.wikipedia.org/wiki/SHA-2) hash.
OP_HASH160             | 0xa9        | Replaces top value with the result of `RIPEMD-160(SHA-256(string)`.
OP_HASH256             | 0xaa        | Replaces top value with the result of `SHA-256(SHA-256(string))`.
OP_CODESEPARATOR       | 0xab        | This opcode is obsolete and does effectively nothing.
OP_CHECKSIG            | 0xac        | (*signature* *pubkey* → true/false) Verifies transaction signature (with [hashtype](signature.md) byte) with a given public key.
OP_CHECKSIGVERIFY      | 0xad        | Same as `OP_CHECKSIG OP_VERIFY`
OP_CHECKMULTISIG       | 0xae        | (OP\_0 *signatures* *M* *pubkeys* *N* → true/false) Verifies transaction signatures (each must have a [hashtype](signature.md) byte) against the given public keys. Signatures must be provided in the same order as corresponding public keys.
OP_CHECKMULTISIGVERIFY | 0xaf        | Same as `OP_CHECKMULTISIG OP_VERIFY`


### 8. Expansion Opcodes

Name                   | Value       |  Description
:----------------------|:------------|:-----------------------------------
OP_NOP1                | 0xb0        | Does nothing.
OP_NOP2                | 0xb1        | Does nothing.
OP_NOP3                | 0xb2        | Does nothing.
OP_NOP4                | 0xb3        | Does nothing.
OP_NOP5                | 0xb4        | Does nothing.
OP_NOP6                | 0xb5        | Does nothing.
OP_NOP7                | 0xb6        | Does nothing.
OP_NOP8                | 0xb7        | Does nothing.
OP_NOP9                | 0xb8        | Does nothing.
OP_NOP10               | 0xb9        | Does nothing.
OP_INVALIDOPCODE       | 0xff        | Invalid opcode. If executed, transaction is invalid.

