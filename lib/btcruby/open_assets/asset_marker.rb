module BTC
  class AssetMarker
    
    MAGIC = "\x4f\x41".freeze
    VERSION1 = "\x01\x00".freeze
    PREFIX_V1 = MAGIC + VERSION1

    attr_accessor :quantities
    attr_accessor :metadata

    attr_reader :data
    attr_reader :output
    attr_reader :script
    
    def initialize(output: nil, script: nil, data: nil, quantities: nil, metadata: nil)
      if output || script
        script ||= output.script
        raise ArgumentError, "Script is not an OP_RETURN script" if !script.op_return_script?
        data = script.op_return_data
        raise ArgumentError, "No pushdata found in script" if !data || data.bytesize == 0
        @output = output
        @script = script
      end
      if data
        data = BTC::Data.ensure_binary_encoding(data)
        
        raise ArgumentError, "Data must be at least 6 bytes long (4 bytes prefix and 2 bytes for varints)" if data.bytesize < 6
        raise ArgumentError, "Prefix is invalid. Expected #{BTC.to_hex(PREFIX_V1)}" if data[0, PREFIX_V1.bytesize] != PREFIX_V1

        offset = PREFIX_V1.bytesize
        count, bytesread = WireFormat.read_varint(data: data, offset: offset)
        raise ArgumentError, "Cannot read Asset Quantity Count varint" if !count
        offset = bytesread
        @quantities = []
        count.times do
          qty, bytesread = WireFormat.read_uleb128(data: data, offset: offset)
          raise ArgumentError, "Cannot read Asset Quantity LEB128 unsigned integer" if !qty
          raise ArgumentError, "Open Assets limit LEB128 encoding for quantities to 9 bytes" if (bytesread - offset) > 9
          @quantities << qty
          offset = bytesread
        end
        metadata, bytesread = WireFormat.read_string(data: data, offset: offset)
        raise ArgumentError, "Cannot read Asset Metadata" if !metadata
        @metadata = metadata
        @data = data[0, bytesread]
      else
        # Initialize with optional attributes
        @quantities = quantities
        @metadata = metadata
      end
    end
    
    def quantities
      @quantities ||= []
    end

    def quantities=(qs)
      @quantities = qs
      @data = nil
      @script = nil
      @output = nil
    end
    
    def metadata
      @metadata ||= "".b
    end
    
    def metadata=(md)
      @metadata = md
      @data = nil
      @script = nil
      @output = nil
    end
    
    def data
      @data ||= begin
        PREFIX_V1 + 
        WireFormat.encode_varint(self.quantities.size) + 
        self.quantities.inject("".b){|buf, qty| buf << WireFormat.encode_uleb128(qty) } +
        WireFormat.encode_string(self.metadata)
      end
    end

    def script
      @script ||= begin
        Script.new << OP_RETURN << self.data
      end
    end

    def output
      @output ||= TransactionOutput.new(value: 0, script: self.script)
    end
  end
end
