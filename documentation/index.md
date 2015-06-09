BTCRuby Reference
=================

Find your topic in the index, or refer to one of the examples below.

Classes and Modules
-------------------

Bitcoin Data Structures                        | Utilities                           | Crypto
:----------------------------------------------|:------------------------------------|:--------------------------
[Constants](constants.md)                      | [Base58](base58.md)                 | [HashFunctions](hash_functions.md)
[Address](address.md)                          | [Core Extensions](extensions.md)    | [Key](key.md)
↳ [PublicKeyAddress](p2pkh.md)                 | [Data](data.md)                     | [Keychain](keychain.md)
↳ [ScriptHashAddress](p2sh.md)                | [Diagnostics](diagnostics.md)       | [OpenSSL](openssl.md)
↳ [WIF](wif.md)                                | [Hash↔ID Conversions](hash_id.md)   |
[Block](block.md)                              | [ProofOfWork](proof_of_work.md)     |
[BlockHeader](block_header.md)                 | [WireFormat](wire_format.md)        |
[Network](network.md)                          |                                     |
[Opcode](opcode.md)                            |                                     |
[Script](script.md)                            |                                     |
[Signatures and Hash Types](signature.md)      |                                     |
[Transaction](transaction.md)                  |                                     |
[TransactionInput](transaction_input.md)       |                                     |
[TransactionOutput](transaction_output.md)     |                                     |
[TransactionBuilder](transaction_builder.md)   |                                     |

Glossary
--------

**[Address](address.md)** is a compact identifier that represents a destination for a Bitcoin payment.
To parse addresses use base class [BTC::Address](address.md). To encode addresses use subclasses [BTC::PublicKeyAddress](p2pkh.md) and [BTC::ScriptHashAddress](p2sh.md).

**[Base58 encoding](base58.md)** is used to encode Bitcoin [addresses](address.md),
private keys in [WIF](wif.md) and extended keys for [BIP32 keychains](keychain.md).

**[Blocks](block.md)** and **[Block Headers](block_header.md)** form a block chain that contains [transactions](transaction.md).

**[BIP32](keychain.md)** ("HD Wallets") is a standard for deriving series of [keys](key.md) or [addresses](address.md) from a single seed.
Use [BTC::Keychain](keychain.md) class to decode extended public and private keys (“xpubs” and “xprvs”) and derive chains of keys.

**[Data](data.md)** is what we call a binary string. BTCRuby uses binary strings by default.
Use methods defined in [BTC::Data](data.md) namespace to convert strings between hex and binary and access raw bytes in a safe manner.

**[Hash functions](hash_functions.md)** used in Bitcoin are accessible via `BTC` namespace: `BTC.hash256`, `BTC.hash160`, `BTC.sha256` and so on.

**[Input](transaction_input.md)** is a part of a bitcoin [transaction](transaction.md) that
unlocks bitcoins stored in the [outputs](transaction_output.md) of the previous transactions.
Every input contains a reference to some output (transaction hash and a numeric index of the output)
and a [signature script](script.md) that typically contains [signatures](key.md) and other data
to satisfy conditions defined by the corresponding output script.

**[Keys](key.md)** allow signing transactions and verifying existing signatures.
Class [BTC::Key](key.md) encapsulates a pair of public and private keys (or only a public key)
and provides methods to sign transactions and verify signatures.

**[Keychain](keychain.md)** is a chain of [keys](key.md) generated from a single seed
(or *extended key*) by a mechanism defined in BIP32.

**[Opcode](opcode.md)** is a basic unit of a [script](script.md). It could represent a piece of binary data
(e.g. a [signature](signature.md)) or an operation on data (e.g. signature verification).
See [BTC::Opcode](opcode.md) class for a list of available opcodes and related conversion methods.

**[Output](transaction_output.md)** is a part of a bitcoin [transaction](transaction.md) that specifies
destination of the bitcoins being transferred. Every output has an amount (in satoshis) and a script (that typically corresponds to an [address](address.md)).

**[P2PKH](p2pkh.md)** (pay-to-pubkey-hash) is a classic type of [address](address.md) that
compresses a public [key](key.md) in a 20-byte hash value. P2PKH-addresses start with "1" on mainnet
and "n" or "m" on testnet. Use [BTC::PublicKeyAddress](p2pkh.md) class to encode these addresses.

**[P2SH](p2sh.md)** (pay-to-script-hash) is a type of [address](address.md) that represents an arbitrary [script](script.md) as a single 20-byte hash.
P2SH-address starts with "3" on mainnet and "2N" or "2M" on testnet. Use [BTC::ScriptHashAddress](p2sh.md) class to encode these addresses.

**[Script](script.md)** is a predicate consisting of [opcodes](opcode.md) that defines control
over bitcoins in a [transaction output](transaction_output.md) or satisfies a predicate when
unlocking (spending) bitcoins in a [transaction input](transaction_input.md). 
To create and inspect scripts, use [BTC::Script](script.md) class.

**[Transaction](transaction.md)** (abbreviated "tx") is an object that represents transfer of bitcoins from one or more [inputs](transaction_input.md) to one or more [outputs](transaction_output.md). Use [BTC::Transaction](transaction.md) class to inspect transactions or create them transactions manually. To build transaction we recommend using [BTC::TransactionBuilder](transaction_builder.md), which takes care of a lot of difficulties and exposes easy to use, yet powerful enough API.

**[Transaction ID](transaction.md)** (abbreviated "txid") is a reversed hex representation of transaction hash. To convert between IDs and hashes of transactions and blocks, use `BTC.hash_from_id` and `BTC.id_from_hash` methods.

**[Transaction Builder](transaction_builder.md)** is a high-level API to build [transactions](transaction,md). It selects unspent [outputs](transaction_output.md), prepares correct [signature scripts](script.md), computes mining fees and takes care of the change.

**[WIF](wif.md)** (Wallet Import Format aka "sipa format") is used to encode a single [private key](key.md) in [Base58check](base58.md) encoding.

**[Wire Format](wire_format.md)** is a low-level binary format to encode network messages. Used to encode transactions and blocks. Higher-level objects expose `data` method that takes care of this encoding, but if you need to compose or parse some custom messages, use [BTC::WireFormat](wire_format.md) class.


Examples
--------

### 1. Generating a Bitcoin address

This example demonstrates how to generate a key and get its address.

```ruby
key = BTC::Key.random

puts key.to_wif # private key in WIF format
# => L4RqZhbn2VsVgy2wCWW8kUPpA4xEkH7WbfPtj1MdFug5MayHzLeT

puts key.address.to_s # public address
# => 1MFqAcAxNsAKj5e6yksZCCyfNukSdDGsEY

puts key.to_wif(network: BTC::Network.testnet)
# => cUnq2cbdTZZkrQWCavKG7ntsnJFeQjDCfhYMqRp8m2L5cL1yHDmc

puts key.address(network: BTC::Network.testnet).to_s
# => n1mnTfFwBtbaWC7ihKqw28BzEuM9YqxRyw
```


### 2. Making Transactions

Transaction builder helps composing arbitrary transactions using just keys or unspent outputs.
It takes care of computing a proper change amount, adding fees and signing inputs.
It is also highly customizable, so you may use it for very complex transactions.

```ruby
builder = BTC::TransactionBuilder.new

# 1. Provide a list of addresses to get unspent outputs from.
#    If address is a WIF instance, it will be used to sign corresponding input
#    If address is a public address (or P2SH), its input will remain unsigned.
builder.input_addresses = [ "L1uyy5qTuGrVXrmrsvHWHgVzW9kKdrp27wBC7Vs6nZDTF2BRUVwy" ]

# 2. Use external API (e.g. Chain.com) to fetch unspent outputs for the input addresses.
#    In this example we simply hard-code a single unspent output.
#    Note: transaction ID and output index must be provided.
builder.unspent_outputs_provider_block = lambda do |addresses, outputs_amount, outputs_size, fee_rate|
  txout = BTC::TransactionOutput.new(
    value: 50_000,
    script: BTC::PublicKeyAddress.parse("17XBj6iFEsf8kzDMGQk5ghZipxX49VXuaV").script,
    transaction_id: "115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e308986",
    index: 0
  )
  [ txout ]
end

# 3. Specify payment address and amount
builder.outputs = [ BTC::TransactionOutput.new(
                        value: 10_000,
                        script: BTC::Address.parse("17XBj6iFEsf8kzDMGQk5ghZipxX49VXuaV").script) ]

# 4. Specify the change address
builder.change_address = BTC::Address.parse("1CBtcGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG")

# 5. Build the transaction and broadcast it.
result = builder.build
tx = result.transaction
puts tx.to_hex

# => 01000000018689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e11
#    000000006b483045022100e280f71106a84a4a1b1a2035eae70266eb53630beab2b59cc8cf
#    f40b1a5bdbb902201dcbae9bb12730fe5563dc37e3a33e064f2efa78ba0af5c0179187aece
#    180b6c0121029f50f51d63b345039a290c94bffd3180c99ed659ff6ea6b1242bca47eb93b5
#    9fffffffff0210270000000000001976a91447862fe165e6121af80d5dde1ecb478ed17056
#    5b88ac30750000000000001976a9147ab89f9fae3f8043dcee5f7b5467a0f0a6e2f7e188ac
#    00000000
```


### 3. Creating a transaction manually

To manually create a transaction, you will need to specify raw inputs,
compute the signature and compose a signature script for each input and
take care of calculating fees and change.

```ruby
include BTC

tx = Transaction.new

# 1. Add a raw input with previous transaction ID and output index.
tx.add_input(TransactionInput.new(
                previous_id: "aa94ab02c182214f090e99a0d57021caffd0f195a81c24602b1028b130b63e31",
                previous_index: 0))

# 2. Add a raw output with a script
tx.add_output(TransactionOutput.new(
                value: 100_000,
                script: PublicKeyAddress.parse("1CBtcGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG").script))

# 3. Get the private key from WIF
key = Key.new(wif: "L1uyy5qTuGrVXrmrsvHWHgVzW9kKdrp27wBC7Vs6nZDTF2BRUVwy")

# 4. Sign the input (assuming it links to an output with address 18oxCAnbuKHDjP7KzLBDj8mLjggDBjE1Q9)
hashtype = BTC::SIGHASH_ALL
sighash = tx.signature_hash(input_index: 0,
                            output_script: Address.parse("18oxCAnbuKHDjP7KzLBDj8mLjggDBjE1Q9").script,
                            hash_type: hashtype)
tx.inputs[0].signature_script = Script.new << (key.ecdsa_signature(sighash) + WireFormat.encode_uint8(hashtype)) << key.public_key

# Get transaction data and broadcast it
puts tx.data # => raw binary data
puts tx.to_hex # hex-encoded data
# => 0100000001313eb630b128102b60241ca895f1d0ffca2170d5a0990e094f2182c102ab94aa
#    000000006a473044022039148258144202301221a305adb38ce0a182ecb4055c6015cdd735
#    8372d7ad6d022008aa259c87177f0e4e887dd0947c57fd140eb8f8a826f14ef8389dbc26ef
#    a7b20121029f50f51d63b345039a290c94bffd3180c99ed659ff6ea6b1242bca47eb93b59f
#    ffffffff01a0860100000000001976a9147ab89f9fae3f8043dcee5f7b5467a0f0a6e2f7e1
#    88ac00000000
```


### 4. Creating a P2SH multisig address

To create a P2SH multisig address you will need a set of public keys.
In the example below we generate three random keys and compose 2-of-3 multisig script
which is then transformed into a P2SH address. To redeem from this address you will need
not only two signatures, but also the original multisig script.

```ruby
keys = [BTC::Key.random, BTC::Key.random, BTC::Key.random]
pubkeys = keys.map(&:public_key)

multisig_script = BTC::Script.multisig(public_keys: pubkeys, signatures_required: 2)
puts multisig_script.to_s # => "OP_2 02c008dc... 03cab527... 024ac920... OP_3 OP_CHECKMULTISIG"

p2sh_script = multisig_script.p2sh_script
puts p2sh_script.to_s # => "OP_HASH160 a6bdcfcac410d1c1acbf34701da382ca34a691a3 OP_EQUAL"

address = p2sh_script.standard_address
puts address.to_s # => 3GtfUjaNBqG9wjw3CCgbxLUrbjtSDg4nDf
```





