module CLI
  abstract class Command
    property name : String?
    property usage : Array(String)
    property description : String?
    property short_help : String?
    property arguments : Hash(String, Argument)
    property options : Array(Option)

    def initialize
      @usage = [] of String
      @arguments = {} of String => Argument
      @options = [] of Option

      setup
    end

    def add_argument(name : String, description : String? = nil, required : Bool = false,
                     kind : ValueKind = :none, default = nil) : Nil
      @arguments[name] = Argument.new(name, description, required, kind, default)
    end

    def add_option(long : String, description : String? = nil, required : Bool = false,
                   kind : ValueKind = :none, default = nil) : Nil
      @options << Option.new(long, nil, description, required, kind, default)
    end

    def add_option(short : String, long : String, description : String? = nil,
                   required : Bool = false, kind : ValueKind = :none, default = nil) : Nil
      @options << Option.new(long, short, description, required, kind, default)
    end

    def setup : Nil
      raise "A name must be set for the command" unless @name
    end

    abstract def execute(args, options) : Nil

    def on_invalid_arguments(args : Array(String)) : NoReturn
      raise "Invalid arguments: #{args.join(", ")}"
    end

    def on_invalid_options(options : Array(String)) : NoReturn
      raise "Invalid options: #{options.join(", ")}"
    end

    def on_missing_arguments(args : Array(Argument)) : NoReturn
      raise "Missing required arguments: '#{args.join(", ")}'"
    end

    def on_missing_options(options : Array(Option)) : NoReturn
      raise "Missing required options: '#{options.join(", ")}'"
    end

    def on_error(ex : Exception) : NoReturn
      raise ex
    end
  end
end
