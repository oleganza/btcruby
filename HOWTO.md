# BTCRuby HOWTO

* [Generating Private/Public Keys](#generating-privatepublic-keys)

## Generating Private/Public Keys

```ruby
require 'btcruby'
require 'btcruby/extensions'

key = BTC::Key.random

prv = key.to_wif # => L2yVhzwp5F7NXUmP31j274MPjnWi7WbFs3qRJEcdrjyBZ9jmEdWb
pub = key.address.to_s # => 15M8ocGxsWtaenLQy6hDKXeLHqQgG3ebpB

puts [prv, pub].join(" - ")
```
