module BTC
  TransactionBuilder
  class TransactionBuilder
    class Error < BTCError; end

    # Change address is not specified
    class MissingChangeAddressError < Error; end

    # Unspent outputs are missing. Maybe because input_addresses are not specified.
    class MissingUnspentOutputsError < Error; end

    # Unspent outputs are not sufficient to build the transaction.
    class InsufficientFundsError < Error; end
  end
end
