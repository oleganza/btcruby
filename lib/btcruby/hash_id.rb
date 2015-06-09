module BTC

  # Transaction ID <-> Transaction Hash conversion
  # Block ID <-> Block Hash conversion

  # Converts string transaction or block ID into binary hash.
  def self.hash_from_id(identifier)
    return nil if !identifier # so we can convert optional ID into optional hash without extra headache
    BTC.from_hex(identifier).reverse
  end

  # Converts binary hash to hex identifier (as a big-endian 256-bit integer).
  def self.id_from_hash(hash)
    return nil if !hash  # so we can convert optional hash into optional ID without extra headache
    BTC.to_hex(hash.reverse)
  end

end