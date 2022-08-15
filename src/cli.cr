require "./application"
require "./argument"
require "./command"
require "./option"
require "./parser"

module CLI
  VERSION = "0.1.0"

  alias Any = String | Int8 | Int16 | Int32 | Int64 | Float32 | Float64 | Bool | Nil | Array(Any) | Hash(Any, Any)

  enum ValueKind
    None
    String
    # Array
  end
end
