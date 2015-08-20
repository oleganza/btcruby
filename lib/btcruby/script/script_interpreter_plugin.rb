module BTC
  # ScriptInterpreterPlugin allows adding extensions to the script machinery without requiring source code meddling.
  # ScriptInterpreter provides several extension points:
  # - extra flags (e.g. requirement for push-only opcodes in signature script)
  # - pre-flight hook to completely take control over both scripts' execution
  # - callback after signature script execution
  # - interior hook to take control over output script execution after signature script is being executed
  # - callback after output script execution
  # - hook for handling the opcodes
  module ScriptInterpreterPlugin
    include ScriptFlags
    include ScriptErrors
    include Opcodes

    # Returns additional flags to be available to #flag? checks during script execution.
    # This way one plugin can affect evaluation of another.
    def extra_flags
      0
    end

    # The first plugin that returns true takes control over both scripts via `handle_scripts`.
    # No other callbacks are called for this plugin or any other.
    # Default value is `false`.
    def should_handle_scripts(interpreter: nil, signature_script: nil, output_script: nil)
      false
    end

    # Returns true/false depending on result of scripts' evaluation
    def handle_scripts(interpreter: nil, signature_script: nil, output_script: nil)
      false
    end

    # Every plugin gets this callback. If plugin return `false`, execution is stopped and interpreter returns `false`.
    # Default value is `true`.
    def did_execute_signature_script(interpreter: nil, signature_script: nil)
      true
    end

    # The first plugin that returns true takes control over output script via #handle_output_script.
    # No other callbacks are called for this plugin or any other.
    # Default value is `false`.
    def should_handle_output_script(interpreter: nil, output_script: nil)
      false
    end

    # Returns true/false depending on result of script's evaluation
    def handle_output_script(interpreter: nil, output_script: nil)
      false
    end

    # Every plugin gets this callback. If plugin return `false`, execution is stopped and interpreter returns `false`.
    # Default value is `true`.
    def did_execute_output_script(interpreter: nil, output_script: nil)
      true
    end

    # The first plugin that returns true takes control over that opcode.
    # Default value is `false`.
    def should_handle_opcode(interpreter: nil, opcode: nil)
      false
    end

    # Returns `false` if failed to execute the opcode.
    def handle_opcode(interpreter: nil, opcode: nil)
      false
    end

  end
end
