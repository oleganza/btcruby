[Index](index.md)

BTC::Diagnostics
================

Diagnostics provides extensive details of inner workings of various algorithms. 
For instance, when script is parsed and detects non-canonical encoding of certain elements,
it is not an error condition, but an unusual case that can be important for debugging.

You can wrap any piece of code in `Diagnostics.current.record { ... }` to collect all diagnostic messages
or use `Diagnostics.current.trace { ... }` to output all the messages to STDERR.

Class Method
------------

#### current

An instance of `BTC::Diagnostics` unique to the current thread.


Instance Methods
----------------

#### last_message

Returns the latest recorded message. See `add_message`.

#### last_info

Returns the latest recorded info object associated with the latest message. See `add_message`.

#### last_item

Returns the `Diagnostics::Item` object that contains latest message and info.

#### add_message(*message*, info: nil)

Records a `message` (String) with an optional `info` object. 

When executed within a `trace {...}` block, `message` is written to STDERR or another stream specified in `trace`.

When executed within a `record {...}` block, an `Item` containing both `message` and `info` is added to an array returned from `record`.

#### record { ... }

Returns an array of all `Item` instances recorded by `add_message` within the block.

```ruby
Diagnostics.current.record do
  Diagnostics.current.add_message("Hello")
  Diagnostics.current.add_message("world")
end.map(&:to_s)
```

```
["Hello", "world"]
```

#### trace(*stream* = $stderr) { ... }

Writes every recorded message to a given stream. Default stream is `$stderr`.

```ruby
Diagnostics.current.trace do
  Diagnostics.current.add_message("Hello")
  Diagnostics.current.add_message("world")
end
```

```
Hello
world
```

Diagnostics::Item
-----------------

Item class represents a pair of `message` (String) and an arbitrary `info` object.

#### message

Message string.

#### info

Additional object of arbitrary type. Default value is `nil`.

#### to_s

Returns `message`.