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
end
