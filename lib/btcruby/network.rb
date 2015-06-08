module BTC
  class Network

    # Name of the network (mainnet or testnet3)
    attr_accessor :name

    # Is testnet (true/false). Alias: testnet?
    attr_accessor :testnet

    # Is mainnet (true/false). Alias: mainnet?
    attr_accessor :mainnet

    # Genesis block for this network
    attr_accessor :genesis_block

    # Genesis block header for this network
    attr_accessor :genesis_block_header

    # Maximum target (lowest difficulty) for this network.
    attr_accessor :max_target

    # Default network when it is not explicitly specified.
    def self.default
      return (@default ||= self.mainnet)
    end

    def self.default=(network)
      @default = network
    end

    def self.mainnet
      @mainnet ||= begin
        network = self.new
        network.name = "mainnet"
        network.genesis_block = Block.genesis_mainnet
        network.genesis_block_header = BlockHeader.genesis_mainnet
        network.max_target = ProofOfWork::MAX_TARGET_MAINNET
        network
      end
    end

    def self.testnet
      @testnet ||= begin
        network = self.new
        network.name = "testnet3"
        network.testnet = true
        network.genesis_block = Block.genesis_testnet
        network.genesis_block_header = BlockHeader.genesis_testnet
        network.max_target = ProofOfWork::MAX_TARGET_TESTNET
        network
      end
    end

    def testnet?; @testnet || false; end
    def testnet;  @testnet || false; end

    def mainnet?; !testnet?; end
    def mainnet;  !testnet?; end
    def mainnet=(flag)
      self.testnet = !flag
    end

    def dup
      network = Network.new
      network.name = self.name.dup
      network.testnet = self.testnet
      network.genesis_block = self.genesis_block
      network.genesis_block_header = self.genesis_block_header
      network
    end

  end
end
