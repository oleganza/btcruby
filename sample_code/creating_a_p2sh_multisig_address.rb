# Creating a P2SH multisig address
# --------------------------------
#
# To create a P2SH multisig address you will need a set of public keys.
# In the example below we generate three random keys and compose 2-of-3 multisig script
# which is then transformed into a P2SH address. To redeem from this address you will need
# not only two signatures, but also the original multisig script.

require_relative "../lib/btcruby.rb"

keys = [BTC::Key.random, BTC::Key.random, BTC::Key.random]
pubkeys = keys.map(&:public_key)

multisig_script = BTC::Script.multisig_script(public_keys: pubkeys, signatures_required: 2)
puts multisig_script.to_s # => "OP_2 03e4e14a... 03b4b3f7... 030fa2ec... OP_3 OP_CHECKMULTISIG"

p2sh_script = multisig_script.p2sh_script
puts p2sh_script.to_s # => "OP_HASH160 26f5b7ad4e890c07b8c55fc551e39d6693c5e984 OP_EQUAL"

address = p2sh_script.standard_address
puts address.to_s # => 35F1xaoodzRZUBJHi6TgA85qPjXQcW8XsQ
