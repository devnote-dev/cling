module Cling
  # The base error for this module.
  class Error < Exception
  end

  # An error raised from a command, or argument/option in a command.
  class CommandError < Error
  end

  # An error raised during a command execution.
  class ExecutionError < Error
  end

  # An error raised during the command line parsing process.
  class ParserError < Error
  end

  # An error raised if the `Value` of an argument or an option is not found/set.
  class ValueNotFound < Error
    def initialize(key : String)
      super "Value not found for key: #{key}"
    end
  end

  # An error used for signalling the end of the current program.
  class ExitProgram < Error
    getter code : Int32

    def initialize(@code : Int32)
    end
  end
end
