# BTC::Mnemonic implements BIP39: mnemonic-based hierarchical deterministic wallets.
# Currently only supports restoring keychain from words. Generating sentence.
require 'openssl'
require 'openssl/digest'
module BTC
  class Mnemonic
    
    def initialize(words: nil, password: "")
      if words.is_a?(String)
        words = words.split(" ")
      end
      # TODO: check if number of words is correct (12, 15, 18, 21, 24)
      @words = words
      @password = password
    end
    
    def seed
      @seed ||= make_seed(words: @words, password: @password)
    end
    
    def keychain
      @keychain ||= Keychain.new(seed: seed)
    end
    
    private
    
    def make_seed(words: nil, password: nil)
      password ||= ""
      
      mnemonic = @words.join(" ").b
      salt = "mnemonic#{password}".b
      
      digest = ::OpenSSL::Digest::SHA512.new
      length = digest.digest_length
      
      return ::OpenSSL::PKCS5.pbkdf2_hmac(
        mnemonic,
        salt,
        2048, # iterations 
        length,
        digest
      )
    end
    
    public
    
    # For manual testing
    
    def print_addresses(range: 0..100, network: BTC::Network.mainnet, account: 0)
      kc = keychain.bip44_keychain(network: network).bip44_account_keychain(account)
      puts "Addresses for account #{account} on #{network.name}"
      puts "Account xpub:          #{kc.xpub}"
      puts "Account external xpub: #{kc.bip44_external_keychain.xpub}"
      puts "Index".ljust(10) + "External Address".ljust(40) + "Internal Address".ljust(40)
      range.each do |i|
        s = ""
        s << "#{i}".ljust(10)
        s << kc.bip44_external_keychain.derived_key(i).address.to_s.ljust(40)
        s << kc.bip44_internal_keychain.derived_key(i).address.to_s.ljust(40)
        puts s
      end
    end
    
  end
end