module BTC
  TransactionBuilder
  class TransactionBuilder
    
    # Interface for signing inputs used by transaction builder.
    # As an alternative, you may provide `WIF` objects as `input_addresses` to have 
    # transaction builder sign simple P2PK and P2PKH inputs automatically.
    module Signer

      # Returns a signing BTC::Key instance to for a given BTC::TransactionOutput that is being spent
      # and a corresponding BTC::Address.
      # Used to sign inputs spending simple P2PK and P2PKH outputs. 
      # Other outputs must be signed via `signature_script_for_input_provider` or directly.
      # If nil is returned, more generic method will be tried.
      def signing_key_for_output(output: nil, address: nil)
        nil
      end

      # Returns a BTC::Script instance that signs BTC::TransactionInput. 
      # Second argument is BTC::TransactionOutput that is being spent in that input.
      # Returns a signature script (BTC::Script) or nil.
      # If nil is returned, input is left unsigned.
      def signature_script_for_input(input: nil, output: nil)
        nil
      end
    end
  end
end
