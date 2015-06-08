require_relative '../spec_helper'

describe BTC::AssetMarker do
  it "should decode marker output" do
    # Data in the marker output      Description
    # -----------------------------  -------------------------------------------------------------------
    # 0x6a                           The OP_RETURN opcode.
    # 0x11                           The PUSHDATA opcode for a 17 bytes payload.
    # 0x4f 0x41                      The Open Assets Protocol tag.
    # 0x01 0x00                      Version 1 of the protocol.
    # 0x03                           There are 3 items in the asset quantity list.
    # 0xac 0x02 0x00 0xe5 0x8e 0x26  The asset quantity list:
    #                                - '0xac 0x02' means output 0 has an asset quantity of 300.
    #                                - Output 1 is skipped and has an asset quantity of 0
    #                                  because it is the marker output.
    #                                - '0x00' means output 2 has an asset quantity of 0.
    #                                - '0xe5 0x8e 0x26' means output 3 has an asset quantity of 624,485.
    #                                - Outputs after output 3 (if any) have an asset quantity of 0.
    # 0x05                           The metadata is 5 bytes long.
    # 0x48 0x65 0x6c 0x6c 0x6f       Some arbitrary metadata.
    output = TransactionOutput.new(value: 0, script: Script.new << OP_RETURN << "4f41010003ac0200e58e260548656c6c6f".from_hex)
    marker = AssetMarker.new(output: output)
    marker.quantities.must_equal [300, 0, 624_485]
    marker.metadata.must_equal "Hello"

    marker = AssetMarker.new(script: output.script)
    marker.quantities.must_equal [300, 0, 624_485]
    marker.metadata.must_equal "Hello"

    marker = AssetMarker.new(data: output.script.op_return_data)
    marker.quantities.must_equal [300, 0, 624_485]
    marker.metadata.must_equal "Hello"
  end

  it "should encode marker output" do
    marker = AssetMarker.new
    marker.data.must_equal "4f4101000000".from_hex
    marker.metadata = "Hello"
    marker.data.must_equal "4f410100000548656c6c6f".from_hex
    marker.quantities = [1]
    marker.data.must_equal "4f41010001010548656c6c6f".from_hex
    marker.quantities = [1, 2]
    marker.data.must_equal "4f4101000201020548656c6c6f".from_hex
    marker.quantities = [300, 0, 624_485]
    marker.data.must_equal "4f41010003ac0200e58e260548656c6c6f".from_hex
  end
end
