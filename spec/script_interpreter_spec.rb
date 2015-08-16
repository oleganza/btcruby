require_relative 'spec_helper'
require_relative 'data/script_valid'
require_relative 'data/script_invalid'

describe BTC::ScriptInterpreter do

  module ScriptTestHelper
    include BTC::ScriptFlags
    extend self

    FLAGS_MAP = {
        "" =>                           SCRIPT_VERIFY_NONE,
        "NONE" =>                       SCRIPT_VERIFY_NONE,
        "P2SH" =>                       SCRIPT_VERIFY_P2SH,
        "STRICTENC" =>                  SCRIPT_VERIFY_STRICTENC,
        "DERSIG" =>                     SCRIPT_VERIFY_DERSIG,
        "LOW_S" =>                      SCRIPT_VERIFY_LOW_S,
        "NULLDUMMY" =>                  SCRIPT_VERIFY_NULLDUMMY,
        "SIGPUSHONLY" =>                SCRIPT_VERIFY_SIGPUSHONLY,
        "MINIMALDATA" =>                SCRIPT_VERIFY_MINIMALDATA,
        "DISCOURAGE_UPGRADABLE_NOPS" => SCRIPT_VERIFY_DISCOURAGE_UPGRADABLE_NOPS,
        "CLEANSTACK" =>                 SCRIPT_VERIFY_CLEANSTACK,
    }

    def parse_script(json_script, expected_result = true)
      # Note: individual 0xXX bytes may not be individually valid pushdatas, but will be valid when composed together.
      # Since BTC::Script parses binary string right away, we need to compose all distinct bytes in a single hex string.
      orig_string = json_script
      json_script = json_script.dup
      oldsize = json_script.size + 1
      while json_script.size != oldsize
        oldsize = json_script.size
        json_script.gsub!(/0x([0-9a-fA-F]+)\s+0x/, "0x\\1")
      end
      json_script.split(" ").inject(BTC::Script.new) do |parsed_script, x|
        if x.size == 0
          # Empty string, ignore.
          parsed_script
        elsif x =~ /^-?\d+$/
          # Number
          n = x.to_i
          if (n == -1) || (n >= 1 and n <= 16)
            parsed_script << BTC::Opcode.opcode_for_small_integer(n)
          else
            parsed_script << BTC::ScriptNumber.new(integer: n).data
          end
        elsif x[0,2] == "0x"
          # Raw hex data, inserted NOT pushed onto stack:
          data = BTC.from_hex(x[2..-1])
          BTC::Script.new(data: parsed_script.data + data)
        elsif x =~ /^'.*'$/
          # Single-quoted string, pushed as data.
          parsed_script << x[1..-2]
        else
          # opcode, e.g. OP_ADD or ADD:
          opcode = BTC::Opcode.opcode_for_name("OP_" + x)
          parsed_script << opcode
        end
      end
    rescue => e
      if expected_result
        # puts "json_script = #{orig_string.inspect}"
        # puts "json_script = #{json_script.inspect}"
        # puts "EXCEPTION: #{e}"
      end
      return nil
    end

    def parse_flags(string)
      string.split(",").inject(0) do |flags, x|
        f = FLAGS_MAP[x] or raise RuntimeError, "unrecognized script flag: #{x.inspect}"
        flags | f
      end
    end

    def check_signature(script_signature: nil, public_key:nil, script:nil)
      @dummy_checksig && script_signature.bytesize > 60
    end

    def verify_script(sig_script, output_script, flags, expected_result, record)
      @dummy_checksig = expected_result
      checker = self
      interpreter = BTC::ScriptInterpreter.new(
        flags: flags,
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

    def verify_scripts(script_data, expected_result)
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
            yield(self, record, sig_script, output_script, flags, expected_result)
            #verify_script(sig_script, output_script, flags, expected_result)
          end
        else
          yield(self, record, sig_script, output_script, flags, expected_result)
          #verify_script(sig_script, output_script, flags, expected_result)
        end
      end
    end

    def debug(msg, object = :nothing)
      puts "\n\n#{msg}#{object == :nothing ? '' : ' ' + object.inspect}\n"
    end
  end

  ScriptTestHelper.verify_scripts(ValidScripts, true) do |helper, record, sig_script, output_script, flags, expected_result|
    it "#{record.inspect} should be valid" do
      sig_script.wont_be_nil
      output_script.wont_be_nil
      helper.verify_script(sig_script, output_script, flags, expected_result, record)
    end
  end

  ScriptTestHelper.verify_scripts(InvalidScripts, false) do |helper, record, sig_script, output_script, flags, expected_result|
    it "#{record.inspect} should be invalid" do
      helper.verify_script(sig_script, output_script, flags, expected_result, record)
    end
  end

end
