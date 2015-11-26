# Shamir's Secret Sharing Scheme (SSSS) with m-of-n rule for 128-bit numbers.
# Author: Oleg Andreev <oleganza@gmail.com>
#
# * Deterministic, extensible algorithm: every combination of secret and threshold produces exactly the same shares on each run. More shares can be generated without invalidating the first ones.
# * This algorithm splits and restores 128-bit secrets with up to 16 shares and up to 16 shares threshold.
# * Secret is a binary 16-byte string below ffffffffffffffffffffffffffffff61.
# * Shares are 17-byte binary strings with first byte indicating threshold and share index (these are necessary for recovery).
# 
# See also: https://en.wikipedia.org/wiki/Shamir%27s_Secret_Sharing
require 'digest/sha2'
require 'securerandom'
module BTC
  module SecretSharing
    extend self
    Order = 0xffffffffffffffffffffffffffffff61 # Largest prime below 2**128: (2**128 - 159)
  
    def random
      be_from_int(SecureRandom.random_number(Order))
    end
  
    # Returns N strings, any M of them are enough to retrieve a secret.
    # Each string encodes X and Y coordinates and also M. X & M takes one byte, Y takes 16 bytes:
    # MMMMXXXX YYYYYYYY YYYYYYYY YYYYYYYY YYYYYYYY YYYYYYYY YYYYYYYY YYYYYYYY YYYYYYYY YYYYYYYY YYYYYYYY YYYYYYYY YYYYYYYY YYYYYYYY YYYYYYYY YYYYYYYY YYYYYYYY
    def split(secret, m, n)
      prime = Order
      secret_num = int_from_be(secret)
      if secret_num >= Order
        raise "Secret cannot be encoded with 128-bit SSSS"
      end
      if !(n >= 1 && n <= 16)
        raise "N must be between 1 and 16"
      end
      if !(m >= 1 && m <= n)
        raise "M must be between 1 and N"
      end
      shares = []
      coef = [secret_num] # polynomial coefficients
      (m - 1).times do |i|
        # Generate unpredictable yet deterministic coefficients for each secret and M.
        coef << int_from_be(prng(secret + m.chr + i.chr))
      end
      n.times do |i|
        x = i + 1
        exp = 1
        y = coef[0]
        while exp < m
          y = (y + (coef[exp] * ((x**exp) % prime) % prime)) % prime
          exp += 1
        end
        # Encode share
        shares << string_from_point(m, x, y)
      end
      shares
    end
  
    # Transforms M 17-byte binary strings into original secret 16-byte binary string.
    # Each share string must be well-formed.
    def restore(shares)
      prime = Order
      shares = shares.dup.uniq
      raise "No shares provided" if shares.size == 0
      points = shares.map{|s| point_from_string(s) } # [[m,x,y],...]
      ms = points.map{|p| p[0]}.uniq
      xs = points.map{|p| p[1]}.uniq
      raise "Shares do not use the same M value" if ms.size > 1
      m = ms.first
      raise "All shares must have unique X values" if xs.size != points.size
      raise "Number of shares should be M or more" if points.size < m
      points = points[0, m] # make sure we have exactly M points
      y = 0
      points.size.times do |formula| # 0..(m-1)
        # Multiply the numerator across the top and denominators across the bottom to do Lagrange's interpolation
        numerator = 1
        denominator = 1
        points.size.times do |count| # 0..(m-1)
          if formula != count # skip element with i == j
            startposition = points[formula][1]
            nextposition = points[count][1]
            numerator = (numerator * -nextposition) % prime
            denominator = (denominator * (startposition - nextposition)) % prime
          end
        end
        value = points[formula][2]
        y = (prime + y + (value * numerator * modinv(denominator, prime))) % prime
      end
      return be_from_int(y)
    end

    def prng(seed)
      x = Order
      s = nil
      pad = "".b
      while x >= Order
        s = Digest::SHA2.digest(Digest::SHA2.digest(seed + pad))[0,16]
        x = int_from_be(s)
        pad = pad + "\x00".b
      end
      s
    end

    # Returns mmmmxxxx yyyyyyyy yyyyyyyy ... (16 bytes of y)
    def string_from_point(m, x, y)
      m = to_nibble(m)
      x = to_nibble(x)
      byte = [(m << 4) + x].pack("C")
      byte + be_from_int(y)
    end
  
    # returns [m, x, y]
    def point_from_string(s)
      byte = s.bytes.first
      m = from_nibble(byte >> 4)
      x = from_nibble(byte & 0x0f)
      y = int_from_be(s[1..-1])
      [m, x, y]
    end
  
    # Encodes values in range 1..16 to one nibble where all values are encoded as-is, 
    # except for 16 which becomes 0. This is to make strings look friendly for common cases when M,N < 16
    def to_nibble(x)
      x == 16 ? 0 : x
    end

    def from_nibble(x)
      x == 0 ? 16 : x
    end

    # Gives the decomposition of the gcd of a and b.  Returns [x,y,z] such that x = gcd(a,b) and y*a + z*b = x
    def gcd_decomposition(a,b)
      if b == 0
        [a, 1, 0]
      else
        n = a/b
        c = a % b
        r = gcd_decomposition(b,c)
        [r[0], r[2], r[1]-r[2]*n]
      end
    end

    # Gives the multiplicative inverse of k mod prime. In other words (k * modInverse(k)) % prime = 1 for all prime > k >= 1  
    def modinv(k, prime)
      k = k % prime
      r = (k < 0) ? -gcd_decomposition(prime,-k)[2] : gcd_decomposition(prime,k)[2]
      return (prime + r) % prime
    end

    def int_from_be(data)
      r = data.unpack("C*").reverse.inject({pos:0, total:0}) do |ctx, c|
        c = c << ctx[:pos]
        ctx[:pos] += 8
        ctx[:total] += c
        ctx
      end
      r[:total]
    end

    def be_from_int(i, pad = 128)
      a = []
      while i > 0
        a.unshift(i % 256)
        i /= 256
      end
      a.pack("C*").rjust(pad / 8, "\x00")
    end

  end
end

if $0 == __FILE__
  
  SSSS = BTC::SecretSharing
  require_relative 'data.rb'
  
  # Usage 
  secret = SSSS.random
  puts "Secret: #{BTC.to_hex(secret)}"
  shares = SSSS.split(secret, 2, 3)
  shares.each do |share|
    puts "Share:  #{BTC.to_hex(share)}"
  end
  restored_secret = SSSS.restore([shares[1], shares[0]])
  puts "Recovered secret with shares 2 and 1: #{BTC.to_hex(restored_secret)}"
  restored_secret = SSSS.restore([shares[0], shares[2]])
  puts "Recovered secret with shares 1 and 3: #{BTC.to_hex(restored_secret)}"
  restored_secret = SSSS.restore([shares[1], shares[2]])
  puts "Recovered secret with shares 2 and 3: #{BTC.to_hex(restored_secret)}"
  
  # Output:
  # Secret: d881c6f74ccac24997bb27040640a8eb
  # Share:  2147018841997da8d92211ad7590f85754
  # Share:  22b581498be6308f68ac6833e71bb0051e
  # Share:  2324010ad632e375f836beba58a667b387
  # Recovered secret with shares 2 and 1: d881c6f74ccac24997bb27040640a8eb
  # Recovered secret with shares 1 and 3: d881c6f74ccac24997bb27040640a8eb
  # Recovered secret with shares 2 and 3: d881c6f74ccac24997bb27040640a8eb
  
  # Test Vectors
  
  test_vectors = [
    {
      "secret" => "31415926535897932384626433832795",
      "1-of-1" => ["1131415926535897932384626433832795"],
      "1-of-2" => ["1131415926535897932384626433832795", "1231415926535897932384626433832795"],
      "2-of-2" => ["215af384f05d9b45f0e4e348f95b371acd", "2284a5b0ba67ddf44ea6422f8e82eb0e05"],
      "1-of-3" => ["1131415926535897932384626433832795", "1231415926535897932384626433832795", "1331415926535897932384626433832795"],
      "2-of-3" => ["215af384f05d9b45f0e4e348f95b371acd", "2284a5b0ba67ddf44ea6422f8e82eb0e05", "23ae57dc847220a2ac67a11623aa9f013d"],
      "3-of-3" => ["316cb005ab037e85ed9c8befbe72fef75c", "321387c8a1b34863197fae486ca60c1b97", "3325c8a20a62b62f16cceb6c6eccaa93a7"],
      "4-of-6" => ["416c4b3a8dc218696f8b1aed23385496eb", "429b14a744ce462bdc71b910b5cf0890ba", "4384d4d7881b01db3881cd0f17457112c8", 
                   "44f0c303944b6b73e265c52a42e9601a3c", "45a61663a602a2f238c80fa43408a7a57b", "466c062ff9e3c8529a531abee5f119b1ac"],
      "10-of-16"=>["a1a8b4077b75b0b18aefa63399d0b8d749", "a2e015e817190296d9ebe29f1c8cdc21c7", "a3c65760010c358c9760cece5da815edb4", "a4129891c5efd375a8367c854ab08010d6",
                   "a53c138386a55b0b35447ca03e44ab4eeb", "a6182993f21038c5d3bf548dac9dee7e20", "a769f010c04a4996b471a82addd4ea05d4", "a88e27a316dda9822f81616b2d48cb5e23",
                   "a9b0298820dc8c26989b6f8a2e8b00c3c4", "aa98042e1bcdf63b7283503ac4ad364380", "ab27bed0235b651dd92e764fa8cea25ba8", "ac05890d2177c48f4ec6cabd1047d9dbdc",
                   "adba7838775b82e4022af68f19d9985368", "aeb96045352c20fd24c6de8563cb2446f2", "af4f51af0a774592f9eabb71aaf0348def", "a06f50a680d22280f31b853d941c7eb158"],
    },
    {
      "secret" => "deadbeefcafebabedeadbeefcafebabe",
      "1-of-1" => ["11deadbeefcafebabedeadbeefcafebabe"],
      "2-of-2" => ["217f21b8a8329e69ea75a518485c8da19d", "221f95b2609a3e19160c9c71a0ee1c887c"],
      "2-of-3" => ["217f21b8a8329e69ea75a518485c8da19d", "221f95b2609a3e19160c9c71a0ee1c887c", "23c009ac1901ddc841a393caf97fab6ebc"],
      "3-of-3" => ["31d6b7c83a2587dd06be735c2ba5c719c0", "32762d76edcca00dd227bccb825a8daa75", "33bd0ecb0ac0474d211a8a0cf3e9526c3e"],
    },
    {
      "secret" => "ffffffffffffffffffffffffffffff60",
      "1-of-1" => ["11ffffffffffffffffffffffffffffff60"],
      "2-of-2" => ["21375c71bcaf077f5946f9e901efb9cf70", "226eb8e3795e0efeb28df3d203df739ee1"],
      "2-of-3" => ["21375c71bcaf077f5946f9e901efb9cf70", "226eb8e3795e0efeb28df3d203df739ee1", "23a61555360d167e0bd4edbb05cf2d6e52"],
      "3-of-3" => ["3112dac40bb910928263e5cf3971c39c8b", "32dec3f6359b1f7671aa60dd821c4969d3", "3363bb967da62cabcdd3712ad9ff916915"],
    },
    {
      "secret" => "00000000000000000000000000000000",
      "1-of-1" => ["1100000000000000000000000000000000"],
      "2-of-2" => ["2125df3f1da76af07c37689382bc8201a6", "224bbe7e3b4ed5e0f86ed127057904034c"],
      "2-of-3" => ["2125df3f1da76af07c37689382bc8201a6", "224bbe7e3b4ed5e0f86ed127057904034c", "23719dbd58f640d174a639ba88358604f2"],
      "3-of-3" => ["31651161eeddabb39134be97908f0d7d9e", "32671d1a7e6d7ef24037990a5285a75164", "33062329aeaf79bc0d088f5845e3cd7b52"],
    }
  ]
  
  test_vectors.each do |test|
    hexsecret = test.delete("secret")
    secret = BTC.from_hex(hexsecret)
    test.each do |rule, defined_shares|
      m, n = rule.split("-of-").map{|x|x.to_i}
      puts "Testing #{hexsecret} #{rule}:"
      shares = SSSS.split(secret, m, n)
      hexshares = shares.map{|s| BTC.to_hex(s)}
      failed = false
      if hexshares != defined_shares
        failed = true
        puts "Failed test:"
        puts "            Expected:  #{defined_shares.inspect}"
        puts "            Generated: #{hexshares.inspect}"
      end
      subshares = hexshares[0...m] # TODO: iterate over various combinations
      restored_secret = SSSS.restore(subshares.map{|s| BTC.from_hex(s)})
      if restored_secret != secret
        failed = true
        puts "Failed #{hexsecret} #{rule} test: failed to restore secret using #{subshares.inspect}"
      end
      if !failed
        puts "Ok."
      end
    end
  end
  
end