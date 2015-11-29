
BTCRuby Release Notes
=====================

1.5 (November 29, 2015)
-----------------------

* `BTC::SecretSharing` changes API to support 96-, 104- and 128-bit secrets.

1.4 (November 26, 2015)
-----------------------

* `BTC::SecretSharing` implements Shamir's Secret Sharing Scheme (SSSS) for splitting 128-bit secrets up to 16 shares.


1.3 (November 24, 2015)
-----------------------

* `BTC::Script#op_return_script?` now returns `true` for all scripts with first opcode `OP_RETURN`, including scripts with just that opcode or non-pushdata opcodes after it.
* `BTC::Script#op_return_data_only_script?` now returns `true` only if there is at least one pushdata chunk after `OP_RETURN` opcode and all subsequent opcodes are pushdata-only.


1.2.2 (November 12, 2015)
-----------------------

* Added support for inserting scripts during script execution in `BTC::ScriptInterpreter`.


1.2.1 (September 8, 2015)
-----------------------

* Added more arithmetic operators to `BTC::ScriptNumber`.


1.2 (September 8, 2015)
-----------------------

* Renamed Script Plugin to Script Extension.


1.1.6 (August 26, 2015)
-----------------------

* Re-defined Issuance ID to not include amount. Now it is defined purely by an outpoint.
* Fixed namespace issue with `BTC::ScriptError`.


1.1.5 (August 20, 2015)
-----------------------

* Fixed namespace issues with `BTC::Opcodes`.
* All tests are running with explicit namespaces.


1.1.4 (August 18, 2015)
-----------------------

* Public API for `ScriptChunk` instances.
* Added `ScriptChunk#data_only?`.
* Added `ScriptChunk#interpreted_data`.


1.1.3 (August 17, 2015)
-----------------------

* Minor fix.


1.1.2 (August 17, 2015)
-----------------------

* Added scripts test suite from Bitcoin Core.
* Added transactions test suite from Bitcoin Core.
* As a result, fixed a few consensus bugs.
* Renamed `TransactionOutpoint` to `Outpoint` (previous name kept for backwards compatibility).


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
