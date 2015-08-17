require_relative 'spec_helper'
require_relative 'data/script_valid'
require_relative 'data/script_invalid'

describe BTC::ScriptInterpreter do

  module ScriptTestHelper
    extend self

    def verify_script(sig_script, output_script, flags, expected_result, record)
      tx = build_spending_transaction(sig_script, build_crediting_transaction(output_script));
      checker = TransactionSignatureChecker.new(transaction: tx, input_index: 0)
      plugins = []
      plugins << P2SHPlugin.new if (flags & ScriptFlags::SCRIPT_VERIFY_P2SH) != 0
      plugins << CLTVPlugin.new if (flags & ScriptFlags::SCRIPT_VERIFY_CHECKLOCKTIMEVERIFY) != 0
      interpreter = ScriptInterpreter.new(
        flags: flags,
        plugins: plugins,
        signature_checker: checker,
        raise_on_failure: false,
      )
      result = interpreter.verify_script(signature_script: sig_script, output_script: output_script)
      if result != expected_result
        # puts "Failed scripts: #{sig_script.to_s.inspect} #{output_script.to_s.inspect} flags #{flags}, expected to #{expected_result ? 'succeed' : 'fail'}".gsub(/OP_/, "")
        # puts "Error: #{interpreter.error.inspect}"
        #debug("Failed #{expected_result ? 'valid' : 'invalid'} script: #{sig_script.to_s.inspect} #{output_script.to_s.inspect} flags #{flags} -- #{record.inspect}")
      end
      result.must_equal expected_result
    end
    
    def debug_filter(record)
      #return record.inspect['"P2PK anyonecanpay"']
      true
    end

    def parse_tests(script_data, expected_result)
      records = script_data.find_all do |record|
        record.size >= 3 # [sigscript, pubkeyscript, flags, ...]
      end
      records.each do |record|
        sig_script, output_script, flags_string, _ = record
        sig_script = parse_script(sig_script, expected_result)
        output_script = parse_script(output_script, expected_result)
        flags = parse_flags(flags_string)

        #puts (sig_script.to_s + " -- " + output_script.to_s) + "; flags = #{flags}"

        if expected_result == false
          if sig_script != nil && output_script != nil
            if debug_filter(record)
              yield(self, record, sig_script, output_script, flags, expected_result)
              #verify_script(sig_script, output_script, flags, expected_result)
            end
          end
        else
          if debug_filter(record)
            yield(self, record, sig_script, output_script, flags, expected_result)
            #verify_script(sig_script, output_script, flags, expected_result)
          end
        end
      end
    end

    def debug(msg, object = :nothing)
      puts "\n\n#{msg}#{object == :nothing ? '' : ' ' + object.inspect}\n"
    end
  end

  ScriptTestHelper.parse_tests(ValidScripts, true) do |helper, record, sig_script, output_script, flags, expected_result|
    it "should validate scripts #{record.inspect}" do
      sig_script.wont_be_nil
      output_script.wont_be_nil
      helper.verify_script(sig_script, output_script, flags, expected_result, record)
    end
  end

  ScriptTestHelper.parse_tests(InvalidScripts, false) do |helper, record, sig_script, output_script, flags, expected_result|
    it "should fail scripts #{record.inspect}" do
      helper.verify_script(sig_script, output_script, flags, expected_result, record)
    end
  end
  
  

end
