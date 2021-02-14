
require 'ffi' # gem install ffi

# Tip: import 'btcruby/extensions' to enable extensions to standard classes (e.g. String#to_hex)
# Extensions are not imported by default to avoid conflicts with other libraries.

require_relative 'btcruby/version.rb'
require_relative 'btcruby/errors.rb'
require_relative 'btcruby/diagnostics.rb'
require_relative 'btcruby/safety.rb'
require_relative 'btcruby/hash_functions.rb'
require_relative 'btcruby/data.rb'
require_relative 'btcruby/openssl.rb'
require_relative 'btcruby/big_number.rb'
require_relative 'btcruby/base58.rb'

require_relative 'btcruby/constants.rb'
require_relative 'btcruby/script/opcode.rb'
require_relative 'btcruby/currency_formatter.rb'
require_relative 'btcruby/network.rb'
require_relative 'btcruby/address.rb'
require_relative 'btcruby/wif.rb'
require_relative 'btcruby/key.rb'
require_relative 'btcruby/keychain.rb'
require_relative 'btcruby/keychain_group.rb'
require_relative 'btcruby/mnemonic.rb'
require_relative 'btcruby/wire_format.rb'
require_relative 'btcruby/hash_id.rb'
require_relative 'btcruby/outpoint.rb'
require_relative 'btcruby/transaction.rb'
require_relative 'btcruby/transaction_input.rb'
require_relative 'btcruby/transaction_output.rb'
require_relative 'btcruby/validation.rb'

require_relative 'btcruby/script/script_error.rb'
require_relative 'btcruby/script/script_flags.rb'
require_relative 'btcruby/script/script_number.rb'
require_relative 'btcruby/script/script_chunk.rb'
require_relative 'btcruby/script/script.rb'
require_relative 'btcruby/script/script_interpreter.rb'
require_relative 'btcruby/script/signature_hashtype.rb'
require_relative 'btcruby/script/signature_checker.rb'
require_relative 'btcruby/script/test_signature_checker.rb'
require_relative 'btcruby/script/transaction_signature_checker.rb'

require_relative 'btcruby/script/script_interpreter_extension.rb'
require_relative 'btcruby/script/p2sh_extension.rb'
require_relative 'btcruby/script/cltv_extension.rb'

require_relative 'btcruby/transaction_builder.rb'
require_relative 'btcruby/proof_of_work.rb'
require_relative 'btcruby/block_header.rb'
require_relative 'btcruby/block.rb'
require_relative 'btcruby/merkle_tree.rb'
require_relative 'btcruby/open_assets.rb'
require_relative 'btcruby/ssss.rb'

# TODO:
# require_relative 'btcruby/curve_point.rb'
# require_relative 'btcruby/script_machine.rb'
# require_relative 'btcruby/merkle_block.rb'
# require_relative 'btcruby/bloom_filter.rb'
# require_relative 'btcruby/processor.rb'
