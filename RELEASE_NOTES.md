
BTCRuby Release Notes
=====================

1.1.2 (August 17, 2015)
---------------------

* Added scripts test suite from Bitcoin Core
* Added transactions test suite from Bitcoin Core
* Renamed `TransactionOutpoint` to `Outpoint` (previous name kept for backwards compatibility)


1.1.1 (July 30, 2015)
---------------------

* Added work computation from bigint and 256-bit hash.


1.1 (July 29, 2015)
--------------------

* Added full script interpreter as in Bitcoin Core 0.11.
* Added array encoding/decoding support to `BTC::WireFormat`.


1.0.9 (July 20, 2015)
--------------------

* Added `int32be` encoding support.


1.0.8 (July 19, 2015)
--------------------

* Added `verify_hashtype` flag to optionally check hashtype byte.

1.0.7 (July 19, 2015)
--------------------

* Script `subscript` and `find_and_delete` APIs.
* Fixed block parsing API (list of transactions was always empty).
* Added OP_CHECKLOCKTIMEVERIFY.

1.0.6 (July 13, 2015)
--------------------

* Consistent aliasing between `==` and `eql?`
* `TransactionOutpoint` implements `hash` method so it can be used as a key in a dictionary.

1.0.5 (July 8, 2015)
--------------------

* Added MerkleTree API.

1.0.4 (July 2, 2015)
--------------------

* Added `register_class` API to extend `BTC::Address` with custom subclasses.
* Added `IssuanceID` class to identify unique issuance outputs of any asset (so this can be used as a "issue-once" identifier). Support for `issuance_id` in processor is pending.

1.0.3 (June 9, 2015)
--------------------

* BTC::Data methods made available as methods on BTC object (`BTC::Data.data_from_hex` -> `BTC.from_hex` etc.)

1.0.2 (June 9, 2015)
--------------------

* Added `Keychain#to_s` (returns `xpub` or `xprv`).
* API cleanup.

1.0.1 (June 9, 2015)
--------------------

* Fixed support for HMAC functions for Ruby 2.2.

1.0.0 (June 8, 2015)
--------------------

* First public release.
