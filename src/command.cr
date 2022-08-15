module CLI
  abstract class Command
    property name : String?
    property usage : Array(String)
    property description : String?
    property short_help : String?
    property arguments : Hash(String, Argument)
    property options : Hash(String, Option)

    def initialize
      @usage = [] of String
      @arguments = {} of String => Argument
      @options = {} of String => Option

      setup
    end

    def add_argument(name : String, description : String? = nil, default = nil) : Nil
      @arguments[name] = Argument.new(name, description, "", default)
    end

    def add_option(long : String, description : String? = nil, default = nil) : Nil
      @options[long] = Option.new(long, nil, description, "", default)
    end

    def add_option(short : String, long : String, description : String? = nil, default = nil) : Nil
      @options[long] = Option.new(long, short, description, "", default)
    end

    def setup : Nil
      raise "A name must be set for the command" unless @name
    end

    abstract def execute(args, options) : Nil

    def on_invalid_arguments(args : Array(Argument)) : NoReturn
      raise "Invalid arguments: #{args.map(&.name).join(',')}"
    end

    def on_missing_argument(arg : Argument) : NoReturn
      raise "Missing required argument '#{arg}'"
    end

    def on_missing_option(op : Option) : NoReturn
      raise "Missing required option '#{op}'"
    end

    def on_command_error(ex : Exception) : NoReturn
      raise ex
    end
  end
end
