module CLI
  abstract class Command
    @application : Application
    property name : String?
    property usage : Array(String)
    property description : String?
    property short_help : String?
    property arguments : Hash(String, Argument)
    property options : Array(Option)

    def initialize(@application)
      @usage = [] of String
      @arguments = {} of String => Argument
      @options = [] of Option

      setup
    end

    def add_argument(name : String, description : String? = nil, required : Bool = false,
                     kind : ValueKind = :none) : Nil
      @arguments[name] = Argument.new(name, description, required, kind)
    end

    def add_option(long : String, *, short : String? = nil, desc : String? = nil,
                   required : Bool = false, kind : ValueKind = :none, default : String? = nil) : Nil
      @options << Option.new(long, short, desc, required, kind, default)
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
