module BTC
  TransactionBuilder
  class TransactionBuilder
    
    # Result object containing transaction itself and various info about it.
    # You get this object from `TransactionBuilder#build` method.
    class Result

      # BTC::Transaction instance. Each input is either signed (if WIF was used)
      # or contains an unspent output's script as its signature_script.
      # Unsigned inputs are marked using #unsigned_input_indexes attribute.
      attr_reader :transaction

      # List of input indexes that are not signed.
      # Empty list means all indexes are signed.
      attr_reader :unsigned_input_indexes

      # Total fee for the composed transaction.
      # Equals (inputs_amount - outputs_amount)
      attr_reader :fee

      # Total amount on the inputs.
      attr_reader :inputs_amount

      # Total amount on the outputs.
      attr_reader :outputs_amount

      # Amount in satoshis sent to a change address.
      # change_amount = outputs_amount - sent_amount
      attr_reader :change_amount

      # Amount in satoshis sent to outputs specified by the user.
      # sent_amount = outputs_amount - change_amount
      attr_reader :sent_amount
      
      def initialize
        self.transaction = Transaction.new
        self.transaction.inputs_amount = 0
        self.unsigned_input_indexes = []
        self.fee = 0
        self.outputs_amount = 0
        self.change_amount = 0
        self.inputs_amount = 0
      end
      
      def inputs_amount=(amount)
        @inputs_amount = amount
        @transaction.inputs_amount = amount
      end
    end    

    # Internal-only setters.
    class Result
      attr_accessor :transaction
      attr_accessor :unsigned_input_indexes
      attr_accessor :fee
      attr_accessor :inputs_amount
      attr_accessor :outputs_amount
      attr_accessor :change_amount
      def sent_amount
        outputs_amount - change_amount
      end

      def unsigned_input_indices
        unsigned_input_indexes
      end

      def unsigned_input_indices=(arr)
        self.unsigned_input_indexes = arr
      end
    end
  end
end
