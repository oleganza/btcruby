module BTC
  class BTCError < StandardError
  end
  class FormatError < BTCError
  end
  class MathError < BTCError
  end
end
