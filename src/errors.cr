module CLI
  class Error < Exception
  end

  class CommandError < Error
  end

  class ParseError < Error
  end
end
