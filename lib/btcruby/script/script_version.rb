module BTC
  class ScriptVersion
    VERSION_DEFAULT = 0
    VERSION_P2SH = 1

    attr_reader :version         # binary string containing the version
    attr_reader :sighash_version

    def initialize(version)
      @version = version
    end
    
    # Returns a matching signature hash version for the given script version.
    # All currently known script versions use sighash version 1.
    def sighash_version
      return 1
    end

    # Returns true if version is known.
    # Unknown versions are supported too, but scripts are not even parsed and interpreted as "anyone can spend".
    def known?
      default? ||
      p2sh?
    end

    def default?
      @version == VERSION_DEFAULT
    end

    def p2sh?
      @version == VERSION_P2SH
    end

    def name
      case version
      when VERSION_DEFAULT
        "Default script"
      when VERSION_P2SH
        "P2SH v1"
      else
        "Unknown script version"
      end
    end
    
    def to_i
      @version
    end
    
    def to_s
      "v#{@version} (#{name})"
    end

  end
end
