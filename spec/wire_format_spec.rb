require_relative 'spec_helper'
require 'stringio'
describe BTC::WireFormat do

  def verify_varint(int, hex)

    raw = hex.from_hex

    # 1a. Encode to buffer
    BTC::WireFormat.write_varint(int).must_equal(raw)

    # 1b. Write to data buffer
    data = "deadbeef".from_hex
    BTC::WireFormat.write_varint(int, data: data)
    data.to_hex.must_equal("deadbeef" + hex)

    # 1c. Write data to stream
    data = "cafebabe".from_hex
    io = StringIO.new(data)
    io.read # scan forward
    BTC::WireFormat.write_varint(int, stream: io)
    data.to_hex.must_equal("cafebabe" + hex)

    # 2a. Decode from data
    BTC::WireFormat.read_varint(data: raw).must_equal [int, raw.bytesize]
    BTC::WireFormat.read_varint(data: "cafebabe".from_hex + raw, offset: 4).must_equal [int, 4 + raw.bytesize]

    # 2b. Decode from stream
    io = StringIO.new(raw + "deadbeef".from_hex)
    BTC::WireFormat.read_varint(stream: io).must_equal [int, raw.bytesize]

    io = StringIO.new("deadbeef".from_hex + raw + "cafebabe".from_hex)
    BTC::WireFormat.read_varint(stream: io, offset: 4).must_equal [int, 4 + raw.bytesize]
  end

  it "should encode/decode canonical varints" do

    verify_varint(0,             "00")
    verify_varint(252,           "fc")
    verify_varint(255,           "fdff00")
    verify_varint(12345,         "fd3930")
    verify_varint(65535,         "fdffff")
    verify_varint(65536,         "fe00000100")
    verify_varint(1234567890,    "fed2029649")
    verify_varint(1234567890123, "ffcb04fb711f010000")
    verify_varint(2**64 - 1,     "ffffffffffffffffff")

  end

  it "should decode non-canonical varints" do

    BTC::WireFormat.read_varint(data: "fd0000".from_hex).first.must_equal 0x00
    BTC::WireFormat.read_varint(data: "fd1100".from_hex).first.must_equal 0x11

    BTC::WireFormat.read_varint(data: "fe00000000".from_hex).first.must_equal 0x00
    BTC::WireFormat.read_varint(data: "fe11000000".from_hex).first.must_equal 0x11
    BTC::WireFormat.read_varint(data: "fe11220000".from_hex).first.must_equal 0x2211

    BTC::WireFormat.read_varint(data: "ff0000000000000000".from_hex).first.must_equal 0x00
    BTC::WireFormat.read_varint(data: "ff1100000000000000".from_hex).first.must_equal 0x11
    BTC::WireFormat.read_varint(data: "ff1122000000000000".from_hex).first.must_equal 0x2211
    BTC::WireFormat.read_varint(data: "ff1122334400000000".from_hex).first.must_equal 0x44332211

  end

  it "should handle errors when decoding varints" do

    proc { BTC::WireFormat.read_varint() }.must_raise ArgumentError
    proc { BTC::WireFormat.read_varint(data: "".from_hex, stream: StringIO.new("")) }.must_raise ArgumentError

    BTC::WireFormat.read_varint(data: "".from_hex).must_equal [nil, 0]
    BTC::WireFormat.read_varint(data: "fd".from_hex).must_equal [nil, 1]
    BTC::WireFormat.read_varint(data: "fd11".from_hex).must_equal [nil, 1]
    BTC::WireFormat.read_varint(data: "fe".from_hex).must_equal [nil, 1]
    BTC::WireFormat.read_varint(data: "fe112233".from_hex).must_equal [nil, 1]
    BTC::WireFormat.read_varint(data: "ff".from_hex).must_equal [nil, 1]
    BTC::WireFormat.read_varint(data: "ff11223344556677".from_hex).must_equal [nil, 1]

  end

  it "should handle errors when encoding varints" do

    proc { BTC::WireFormat.write_varint(-1) }.must_raise ArgumentError
    proc { BTC::WireFormat.write_varint(nil) }.must_raise ArgumentError
    proc { BTC::WireFormat.write_varint(2**64) }.must_raise ArgumentError
    proc { BTC::WireFormat.write_varint(2**64 + 1) }.must_raise ArgumentError

  end

  def verify_varstring(string, hex)
    raw = hex.from_hex

    # 1a. Encode to buffer
    BTC::WireFormat.write_string(string).must_equal(raw)

    # 1b. Write to data buffer
    data = "deadbeef".from_hex
    BTC::WireFormat.write_string(string, data: data)
    data.to_hex.must_equal("deadbeef" + hex)

    # 1c. Write data to stream
    data = "cafebabe".from_hex
    io = StringIO.new(data)
    io.read # scan forward
    BTC::WireFormat.write_string(string, stream: io)
    data.to_hex.must_equal("cafebabe" + hex)

    # 2a. Decode from data
    BTC::WireFormat.read_string(data: raw).must_equal [string.b, raw.bytesize]
    BTC::WireFormat.read_string(data: "cafebabe".from_hex + raw, offset: 4).must_equal [string.b, 4 + raw.bytesize]

    # 2b. Decode from stream
    io = StringIO.new(raw + "deadbeef".from_hex)
    BTC::WireFormat.read_string(stream: io).must_equal [string.b, raw.bytesize]

    io = StringIO.new("deadbeef".from_hex + raw + "cafebabe".from_hex)
    BTC::WireFormat.read_string(stream: io, offset: 4).must_equal [string.b, 4 + raw.bytesize]
  end

  it "should encode/decode canonical varstrings" do
    verify_varstring("", "00")
    verify_varstring("\x01", "0101")
    verify_varstring(" ",   "0120")
    verify_varstring("  ",  "022020")
    verify_varstring("   ", "03202020")
    verify_varstring("\xca\xfe\xba\xbe", "04cafebabe")
    verify_varstring("тест", "08d182d0b5d181d182") # 4-letter russian word for "test" (2 bytes per letter in UTF-8)
    verify_varstring("\x42"*255, "fdff00" + "42"*255)
    verify_varstring("\x42"*(256*256), "fe00000100" + "42"*(256*256))
  end

  it "should handle errors when decoding varstrings" do

    proc { BTC::WireFormat.read_string() }.must_raise ArgumentError
    proc { BTC::WireFormat.read_string(data: "".from_hex, stream: StringIO.new("")) }.must_raise ArgumentError

    BTC::WireFormat.read_string(data: "".from_hex).must_equal [nil, 0]
    BTC::WireFormat.read_string(data: "fd".from_hex).must_equal [nil, 1]
    BTC::WireFormat.read_string(data: "fd11".from_hex).must_equal [nil, 1]
    BTC::WireFormat.read_string(data: "fe".from_hex).must_equal [nil, 1]
    BTC::WireFormat.read_string(data: "fe112233".from_hex).must_equal [nil, 1]
    BTC::WireFormat.read_string(data: "ff".from_hex).must_equal [nil, 1]
    BTC::WireFormat.read_string(data: "ff11223344556677".from_hex).must_equal [nil, 1]

    # Not enough data in the string
    BTC::WireFormat.read_string(data: "030102".from_hex).must_equal [nil, 1]
    BTC::WireFormat.read_string(stream: StringIO.new("030102".from_hex)).must_equal [nil, 3]

    BTC::WireFormat.read_string(data: "fd03000102".from_hex).must_equal [nil, 3]
    BTC::WireFormat.read_string(stream: StringIO.new("fd03000102".from_hex)).must_equal [nil, 5]

  end

  it "should handle errors when encoding varstrings" do
    proc { BTC::WireFormat.write_string(nil) }.must_raise ArgumentError
  end

  def verify_fixint(int_type, int, hex)
    raw = hex.from_hex

    # Check data
    v, len = BTC::WireFormat.send("read_#{int_type}", data: raw)
    v.must_equal int
    len.must_equal raw.size

    # Check data + offset + tail
    v, len = BTC::WireFormat.send("read_#{int_type}", data: "abc" + raw + "def", offset: 3)
    v.must_equal int
    len.must_equal raw.size + 3

    # Check stream
    v, len = BTC::WireFormat.send("read_#{int_type}", stream: StringIO.new(raw))
    v.must_equal int
    len.must_equal raw.size

    # Check stream + offset + tail
    v, len = BTC::WireFormat.send("read_#{int_type}", stream: StringIO.new("abc" + raw + "def"), offset: 3)
    v.must_equal int
    len.must_equal raw.size + 3

    BTC::WireFormat.send("encode_#{int_type}", int).must_equal raw
  end

  it "should encode/decode fix-size ints" do

    verify_fixint(:uint8, 0, "00")
    verify_fixint(:uint8, 0x7f, "7f")
    verify_fixint(:uint8, 0x80, "80")
    verify_fixint(:uint8, 0xff, "ff")

    verify_fixint(:int8, 0, "00")
    verify_fixint(:int8, 127, "7f")
    verify_fixint(:int8, -128, "80")
    verify_fixint(:int8, -1, "ff")

    verify_fixint(:uint16le, 0, "0000")
    verify_fixint(:uint16le, 0x7f, "7f00")
    verify_fixint(:uint16le, 0x80, "8000")
    verify_fixint(:uint16le, 0xbeef, "efbe")
    verify_fixint(:uint16le, 0xffff, "ffff")

    verify_fixint(:int16le, 0, "0000")
    verify_fixint(:int16le, 0x7f, "7f00")
    verify_fixint(:int16le, 0x80, "8000")
    verify_fixint(:int16le, -(1<<15), "0080")
    verify_fixint(:int16le, -1, "ffff")

    verify_fixint(:uint32le, 0, "00000000")
    verify_fixint(:uint32le, 0x7f, "7f000000")
    verify_fixint(:uint32le, 0x80, "80000000")
    verify_fixint(:uint32le, 0xbeef, "efbe0000")
    verify_fixint(:uint32le, 0xdeadbeef, "efbeadde")
    verify_fixint(:uint32le, 0xffffffff, "ffffffff")

    verify_fixint(:uint64le, 0, "0000000000000000")
    verify_fixint(:uint64le, 0x7f, "7f00000000000000")
    verify_fixint(:uint64le, 0x80, "8000000000000000")
    verify_fixint(:uint64le, 0xbeef, "efbe000000000000")
    verify_fixint(:uint64le, 0xdeadbeef, "efbeadde00000000")
    verify_fixint(:uint64le, 0xdeadbeefcafebabe, "bebafecaefbeadde")
    verify_fixint(:uint64le, 0xffffffffffffffff, "ffffffffffffffff")

    verify_fixint(:int64le, 0, "0000000000000000")
    verify_fixint(:int64le, 0x7f, "7f00000000000000")
    verify_fixint(:int64le, 0x80, "8000000000000000")
    verify_fixint(:int64le, 0xbeef, "efbe000000000000")
    verify_fixint(:int64le, 0xdeadbeef, "efbeadde00000000")
    verify_fixint(:int64le, -(1<<63), "0000000000000080")
    verify_fixint(:int64le, -1, "ffffffffffffffff")

  end
  
  def verify_uleb128(int, hex)

    raw = hex.from_hex

    # 1a. Encode to buffer
    BTC::WireFormat.write_uleb128(int).must_equal(raw)

    # 1b. Write to data buffer
    data = "deadbeef".from_hex
    BTC::WireFormat.write_uleb128(int, data: data)
    data.to_hex.must_equal("deadbeef" + hex)

    # 1c. Write data to stream
    data = "cafebabe".from_hex
    io = StringIO.new(data)
    io.read # scan forward
    BTC::WireFormat.write_uleb128(int, stream: io)
    data.to_hex.must_equal("cafebabe" + hex)

    # 2a. Decode from data
    BTC::WireFormat.read_uleb128(data: raw).must_equal [int, raw.bytesize]
    BTC::WireFormat.read_uleb128(data: "cafebabe".from_hex + raw, offset: 4).must_equal [int, 4 + raw.bytesize]

    # 2b. Decode from stream
    io1 = StringIO.new(raw)
    io2 = StringIO.new(raw + "deadbeef".from_hex)
    BTC::WireFormat.read_uleb128(stream: io1).must_equal [int, raw.bytesize]
    BTC::WireFormat.read_uleb128(stream: io2).must_equal [int, raw.bytesize]

    io1 = StringIO.new("deadbeef".from_hex + raw)
    io2 = StringIO.new("deadbeef".from_hex + raw + "cafebabe".from_hex)
    BTC::WireFormat.read_uleb128(stream: io1, offset: 4).must_equal [int, 4 + raw.bytesize]
    BTC::WireFormat.read_uleb128(stream: io2, offset: 4).must_equal [int, 4 + raw.bytesize]
  end
  
  
  it "should encode/decode LEB128-encoded unsigned integers" do
    verify_uleb128(0, "00")
    verify_uleb128(1, "01")
    verify_uleb128(127, "7f")
    verify_uleb128(128, "8001")
    verify_uleb128(0xff, "ff01")
    verify_uleb128(0x100, "8002")
    verify_uleb128(300, "ac02")
    verify_uleb128(624485, "e58e26")
    verify_uleb128(0xffffff, "ffffff07")
    verify_uleb128(0x1000000, "80808008")
    verify_uleb128(2**64, "80808080808080808002")
  end

end
