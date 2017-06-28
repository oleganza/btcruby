module BTC
  # Versioned script is a wrapper around a regular script with a version prefix.
  # Note that we support version of any length, but do not parse and interpret unknown versions.
  class VersionedScript
    
    attr_reader :version        # Integer
    attr_reader :data           # Raw data representing script wrapped in VersionedScript. For 256-bit P2SH it's just a hash, not a script.
    attr_reader :wrapper_script # BTC::Script that wraps version + data
    attr_reader :script_version # BTC::ScriptVersion
    attr_reader :inner_script   # BTC::Script derived from data, if it makes sense for the given version. 
    
    # Initializers:
    # - `VersionedScript.new(wrapper_script:)` that wraps the version and inner script data.
    # - `VersionedScript.new(version:, data:)` where version is one of ScriptVersion::VERSION_* and data is a raw inner script data (hash for p2sh256).
    # - `VersionedScript.new(p2sh_redeem_script:)` creates a versioned script with p2sh hash of the redeem script.
    def initialize(wrapper_script: nil,
                   version: nil, data: nil,
                   script: nil,
                   p2sh_redeem_script: nil,
                   )
      if wrapper_script
        if !wrapper_script.versioned_script?
          raise ArgumentError, "Script is not a canonical versioned script with minimal pushdata encoding"
        end
        @wrapper_script = wrapper_script
        fulldata = BTC::Data.ensure_binary_encoding(wrapper_script.chunks.first.pushdata)
        @version = fulldata.bytes[0]
        @data = fulldata[1..-1]
      elsif script
        @version = ScriptVersion::VERSION_DEFAULT
        @data = script.data
      elsif p2sh_redeem_script
        @version = ScriptVersion::VERSION_P2SH256
        @data = BTC.hash256(p2sh_redeem_script.data)
      else
        @version = version or raise ArgumentError, "Version is missing"
        @data = data
      end
    end
    
    def wrapper_script
      @wrapper_script ||= BTC::Script.new << (@version.chr.b + @data)
    end
    
    # Returns inner BTC::Script if it's a default script
    def inner_script
      if script_version.default?
        BTC::Script.new(data: data)
      else
        nil
      end
    end
    
    def script_version
      @script_version ||= ScriptVersion.new(@version)
    end

    def known_version?
      script_version.known?
    end
    
  end
end

