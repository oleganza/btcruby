# Using transaction builder
# -------------------------
# 
# Transaction builder helps composing arbitrary transactions using just keys or unspent outputs.
# It takes care of computing a proper change amount, adding fees and signing inputs.
# It is also highly customizable, so you may use it for very complex transactions.

require_relative "../lib/btcruby.rb"

builder = BTC::TransactionBuilder.new

# 1. Provide a list of address to get unspent outputs from.
#    If address is a WIF instance, it will be used to sign corresponding input
#    If address is a public address (or P2SH), its input will remain unsigned.
builder.input_addresses = [ BTC::Key.new(wif: "L1uyy5qTuGrVXrmrsvHWHgVzW9kKdrp27wBC7Vs6nZDTF2BRUVwy").to_wif_object ]

# 2. Use external API (e.g. Chain.com) to fetch unspent outputs for the input addresses.
#    In this example we simply hard-code a single unspent output.
#    Note: transaction ID and output index must be provided.
builder.unspent_outputs_provider_block = lambda do |addresses, outputs_amount, outputs_size, fee|
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
                        script: BTC::PublicKeyAddress.parse("17XBj6iFEsf8kzDMGQk5ghZipxX49VXuaV").script) ]

# 4. Specify the change address
builder.change_address = BTC::PublicKeyAddress.parse("1CBtcGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG")

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
