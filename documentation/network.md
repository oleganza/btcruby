[Index](index.md)

BTC::Network
============

Network object specifies one of Bitcoin networks: `mainnet` or `testnet`.
Network affects formatting of [addresses](address.md), private keys in [WIF](wif.md) format and
extended private and public keys in [BIP32 Keychains](keychain.md).

You typically use network by asking a specific object whether it belongs to mainnet or testnet:

```ruby
Address.parse("1A39uDWJkaPT2o5qr5dVBdvhZtNXeSNXM4").network.mainnet? # => true
Address.parse("mipcBbFg9gMiCh81Kj8tqqdgoZub1ZJRfn").network.testnet? # => true
WIF.parse("L3p8oAcQTtuokSCRHQ7i4MhjWc9zornvpJLfmg62sYpLRJF9woSu").network.testnet? # => false
Keychain.new(xpub: "tpubD6NzVbkrYhZ4YFb9G...").network.mainnet? # => false
```

Class Methods
-------------

#### default

Current default network used when creating a [BTC::Key](key.md) or [BTC::Keychain](keychain.md) without specifying network explicitly.
By default equals `BTC::Network.mainnet`.

You may use this to validate user input:

```ruby
address = Address.parse(user_entered_address)
if address.network != Network.default
  raise "Entered address is not compatible with the network used by application!"
end
```

#### default=(network)

Sets the default network to be used for all new objects that do not explicitly specify network.
This setting does not affect already created objects that have some network specified.

#### mainnet

Returns a singleton object representing the "main" Bitcoin network.

#### testnet

Returns a singleton object representing the "testnet3" Bitcoin network.


Instance Methods
----------------

#### name

Returns a name of the network (`"mainnet"` or `"testnet"`).

#### mainnet?

Returns `true` if this network is mainnet.

#### testnet?

Returns `true` if this network is testnet3.

#### genesis_block

Returns an instance of `BTC::Block` containing the genesis block for this network.

#### genesis\_block\_header

Returns an instance of `BTC::BlockHeader` containing a header of the genesis block for this network.

#### max_target

Returns a maximum target for this network (as native Bignum type). See also [proof of work conversion methods](proof_of_work.md).
