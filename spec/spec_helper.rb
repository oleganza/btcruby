require 'minitest/spec'
require 'minitest/autorun'

require_relative '../lib/btcruby'
require_relative '../lib/btcruby/extensions'

# So every test can access classes directly without prefixing them with BTC::
include BTC
