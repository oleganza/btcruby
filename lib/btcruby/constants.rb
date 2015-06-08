module BTC

  # Satoshi is the smallest unit representable in Bitcoin transactions.
  SATOSHI = 1

  # 100 mln satoshis is one Bitcoin
  COIN = 100_000_000

  # 1 bit is 100 satoshis (1 millionth of a bitcoin)
  BIT  = 100

  # Network Rules (changing these will result in incompatibility with other nodes)

  # The maximum allowed size for a serialized block, in bytes
  MAX_BLOCK_SIZE = 1000000

  # The maximum allowed number of signature check operations in a block
  MAX_BLOCK_SIGOPS = MAX_BLOCK_SIZE/50

  # No amount larger than this (in satoshis) is valid
  MAX_MONEY = 21_000_000 * COIN

  # Coinbase transaction outputs can only be spent after this number of new blocks
  COINBASE_MATURITY = 100

  # Threshold for BTC::Transaction#lock_time: below this value it is interpreted
  # as a block number, otherwise as UNIX timestamp.
  LOCKTIME_THRESHOLD = 500000000 # Tue Nov  5 00:53:20 1985 UTC (max block number is in year ≈11521)

  # P2SH BIP16 didn't become active until Apr 1 2012.
  # All txs before this timestamp should not be verified with P2SH rule.
  BIP16_TIMESTAMP = 1333238400

  # Scripts longer than 10000 bytes are invalid.
  MAX_SCRIPT_SIZE = 10000

  # Maximum number of bytes per "pushdata" operation
  MAX_SCRIPT_ELEMENT_SIZE = 520 # bytes

  # Number of public keys allowed for OP_CHECKMULTISIG
  MAX_KEYS_FOR_CHECKMULTISIG = 20

  # Maximum number of operations allowed per script (excluding pushdata operations and OP_<N>)
  # Multisig op additionally increases count by a number of pubkeys.
  MAX_OPS_PER_SCRIPT = 201

  # Soft Rules (can bend these without becoming incompatible with everyone)

  # The maximum number of entries in an 'inv' protocol message
  MAX_INV_SZ = 50000

  # The maximum size for mined blocks
  MAX_BLOCK_SIZE_GEN = MAX_BLOCK_SIZE / 2

  # The maximum size for transactions we're willing to relay/mine
  MAX_STANDARD_TX_SIZE = MAX_BLOCK_SIZE_GEN / 5


end
