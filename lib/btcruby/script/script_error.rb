module BTC
  SCRIPT_ERR_OK = 0
  SCRIPT_ERR_UNKNOWN_ERROR = 1
  SCRIPT_ERR_EVAL_FALSE = 2
  SCRIPT_ERR_OP_RETURN = 3

  # Max sizes
  SCRIPT_ERR_SCRIPT_SIZE = 4
  SCRIPT_ERR_PUSH_SIZE = 5
  SCRIPT_ERR_OP_COUNT = 6
  SCRIPT_ERR_STACK_SIZE = 7
  SCRIPT_ERR_SIG_COUNT = 8
  SCRIPT_ERR_PUBKEY_COUNT = 9

  # Failed verify operations
  SCRIPT_ERR_VERIFY = 10
  SCRIPT_ERR_EQUALVERIFY = 11
  SCRIPT_ERR_CHECKMULTISIGVERIFY = 12
  SCRIPT_ERR_CHECKSIGVERIFY = 13
  SCRIPT_ERR_NUMEQUALVERIFY = 14

  # Logical/Format/Canonical errors
  SCRIPT_ERR_BAD_OPCODE = 15
  SCRIPT_ERR_DISABLED_OPCODE = 16
  SCRIPT_ERR_INVALID_STACK_OPERATION = 17
  SCRIPT_ERR_INVALID_ALTSTACK_OPERATION = 18
  SCRIPT_ERR_UNBALANCED_CONDITIONAL = 19

  # OP_CHECKLOCKTIMEVERIFY
  SCRIPT_ERR_NEGATIVE_LOCKTIME = 20
  SCRIPT_ERR_UNSATISFIED_LOCKTIME = 21

  # BIP62
  SCRIPT_ERR_SIG_HASHTYPE = 22
  SCRIPT_ERR_SIG_DER = 23
  SCRIPT_ERR_MINIMALDATA = 24
  SCRIPT_ERR_SIG_PUSHONLY = 25
  SCRIPT_ERR_SIG_HIGH_S = 26
  SCRIPT_ERR_SIG_NULLDUMMY = 27
  SCRIPT_ERR_PUBKEYTYPE = 28
  SCRIPT_ERR_CLEANSTACK = 29

  # softfork safeness
  SCRIPT_ERR_DISCOURAGE_UPGRADABLE_NOPS = 30
  
  class ScriptError
    attr_reader :code
    attr_reader :message
    attr_reader :description

    def initialize(code, message = nil)
      @code = code
      @message = message
    end
    
    def code_name
      self.class.constants.find{|n| self.class.const_get(n) == @code }
    end
    
    def inspect
      "#<#{self.class}:#{code} #{description} (#{code_name})>"
    end
    
    def description
      builtin_description + (@message ? ". #{@message}." : "")
    end
    
    def builtin_description
      case @code
      when SCRIPT_ERR_OK
          return "No error"
      when SCRIPT_ERR_EVAL_FALSE
          return "Script evaluated without error but finished with a false/empty top stack element"
      when SCRIPT_ERR_VERIFY
          return "Script failed an OP_VERIFY operation"
      when SCRIPT_ERR_EQUALVERIFY
          return "Script failed an OP_EQUALVERIFY operation"
      when SCRIPT_ERR_CHECKMULTISIGVERIFY
          return "Script failed an OP_CHECKMULTISIGVERIFY operation"
      when SCRIPT_ERR_CHECKSIGVERIFY
          return "Script failed an OP_CHECKSIGVERIFY operation"
      when SCRIPT_ERR_NUMEQUALVERIFY
          return "Script failed an OP_NUMEQUALVERIFY operation"
      when SCRIPT_ERR_SCRIPT_SIZE
          return "Script is too big"
      when SCRIPT_ERR_PUSH_SIZE
          return "Push value size limit exceeded"
      when SCRIPT_ERR_OP_COUNT
          return "Operation limit exceeded"
      when SCRIPT_ERR_STACK_SIZE
          return "Stack size limit exceeded"
      when SCRIPT_ERR_SIG_COUNT
          return "Signature count negative or greater than pubkey count"
      when SCRIPT_ERR_PUBKEY_COUNT
          return "Pubkey count negative or limit exceeded"
      when SCRIPT_ERR_BAD_OPCODE
          return "Opcode missing or not understood"
      when SCRIPT_ERR_DISABLED_OPCODE
          return "Attempted to use a disabled opcode"
      when SCRIPT_ERR_INVALID_STACK_OPERATION
          return "Operation not valid with the current stack size"
      when SCRIPT_ERR_INVALID_ALTSTACK_OPERATION
          return "Operation not valid with the current altstack size"
      when SCRIPT_ERR_OP_RETURN
          return "OP_RETURN was encountered"
      when SCRIPT_ERR_UNBALANCED_CONDITIONAL
          return "Invalid OP_IF construction"
      when SCRIPT_ERR_NEGATIVE_LOCKTIME
          return "Negative locktime"
      when SCRIPT_ERR_UNSATISFIED_LOCKTIME
          return "Locktime requirement not satisfied"
      when SCRIPT_ERR_SIG_HASHTYPE
          return "Signature hash type missing or not understood"
      when SCRIPT_ERR_SIG_DER
          return "Non-canonical DER signature"
      when SCRIPT_ERR_MINIMALDATA
          return "Data push larger than necessary"
      when SCRIPT_ERR_SIG_PUSHONLY
          return "Only non-push operators allowed in signatures"
      when SCRIPT_ERR_SIG_HIGH_S
          return "Non-canonical signature: S value is unnecessarily high"
      when SCRIPT_ERR_SIG_NULLDUMMY
          return "Dummy CHECKMULTISIG argument must be zero"
      when SCRIPT_ERR_DISCOURAGE_UPGRADABLE_NOPS
          return "NOPx reserved for soft-fork upgrades"
      when SCRIPT_ERR_PUBKEYTYPE
          return "Public key is neither compressed or uncompressed"
      when SCRIPT_ERR_UNKNOWN_ERROR
      end
      "unknown error"
    end
  end
end

if $0 == __FILE__
  puts BTC::ScriptError.new(BTC::SCRIPT_ERR_SIG_HIGH_S).inspect
end

