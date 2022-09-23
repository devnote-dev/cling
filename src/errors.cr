module CLI
  class Error < Exception
  end

  class CommandError < Error
  end

  class NotFoundError < CommandError
    def initialize
      super "Command not found"
    end
  end

  class ParseError < Error
  end
end
