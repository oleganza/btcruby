# Creating a transaction manually
# -------------------------------
#
# To manually create a transaction, you will need to specify raw inputs,
# compute the signature and compose a signature script for each input and
# take care of calculating a change amount correctly.

require_relative "../lib/btcruby.rb"

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
                            output_script: PublicKeyAddress.parse("18oxCAnbuKHDjP7KzLBDj8mLjggDBjE1Q9").script,
                            hash_type: hashtype)
tx.inputs[0].signature_script = Script.new << (key.ecdsa_signature(sighash) + WireFormat.encode_uint8(hashtype)) << key.public_key

# Get transaction data and broadcast it
puts "Binary transaction:"
puts tx.data # => raw binary data
puts "Hex transaction:"
puts tx.to_hex # hex-encoded data
# => 0100000001313eb630b128102b60241ca895f1d0ffca2170d5a0990e094f2182c102ab94aa
#    000000006a473044022039148258144202301221a305adb38ce0a182ecb4055c6015cdd735
#    8372d7ad6d022008aa259c87177f0e4e887dd0947c57fd140eb8f8a826f14ef8389dbc26ef
#    a7b20121029f50f51d63b345039a290c94bffd3180c99ed659ff6ea6b1242bca47eb93b59f
#    ffffffff01a0860100000000001976a9147ab89f9fae3f8043dcee5f7b5467a0f0a6e2f7e1
#    88ac00000000
