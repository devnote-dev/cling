require "./application"
require "./argument"
require "./command"
require "./option"
require "./parser"

module CLI
  VERSION = "0.1.0"

  enum ValueKind
    None
    String
    # Array
  end
end
