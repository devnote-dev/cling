module CLI
  abstract class Command
    property aliases : Array(String)
    property usage : Array(String)
    property header : String?
    property summary : String?
    property description : String?
    property footer : String?
    property parent : Command?
    property children : Hash(String, Command)
    property arguments : Hash(String, Argument)
    property options : Hash(String, Option)
    property? hidden : Bool
    property? inherit_borders : Bool
    property? inherit_options : Bool
    property stdin : IO = STDIN
    property stdout : IO = STDOUT
    property stderr : IO = STDERR
    @help_template : String?

    def initialize(*, aliases : Array(String)? = nil, usage : Array(String)? = nil,
                   @header : String? = nil, @summary : String? = nil, @description : String? = nil,
                   @footer : String? = nil, @parent : Command? = nil, children : Array(Command)? = nil,
                   arguments : Hash(String, Argument)? = nil, options : Hash(String, Option)? = nil,
                   @hidden : Bool = false, @inherit_borders : Bool = true, @inherit_options : Bool = true)
      @aliases = aliases || [] of String
      @usage = usage || [] of String
      @children = children || {} of String => Command
      @arguments = arguments || {} of String => Argument
      @options = options || {} of String => Option

      setup
    end

    abstract def setup : Nil

    def name : String
      @name || raise CommandError.new "No name has been set for command"
    end

    def name=(@name : String)
    end

    def is?(name n : String) : Bool
      @name == n || @aliases.includes? n
    end

    def help_template : String
      @help_template
    end

    def help_template=(@help_template : String?)
    end

    def add_command(command : Command) : Nil
      raise ArgumentError.new "Duplicate command '#{command.name}'" if @children.has_key? command.name
      command.aliases.each do |a|
        raise ArgumentError.new "Duplicate command alias '#{a}'" if @children.values.any? &.is? a
      end

      command.parent = self
      if command.inherit_borders?
        command.header = @header
        command.footer = @footer
      end

      command.options.merge! @options if command.inherit_options?
      @children[command.name] = command
    end

    def add_commands(*commands : Command) : Nil
      commands.each { |c| add_command(c) }
    end

    def add_argument(name : String, *, desc : String? = nil, required : Bool = false) : Nil
      raise ArgumentError.new "Duplicate argument '#{name}'" if @arguments.has_key? name
      @arguments[name] = Argument.new(name, desc, required)
    end

    def add_option(long : String, *, desc : String? = nil, required : Bool = false,
                   has_value : Bool = false, default : Value::Type = nil) : Nil
      raise ArgumentError.new "Duplicate flag option '#{long}'" if @options.has_key? long

      @options[long] = Option.new(long, nil, desc, required, has_value, default)
    end

    def add_option(short : Char, long : String, *, desc : String? = nil, required : Bool = false,
                   has_value : Bool = false, default : Value::Type = nil) : Nil
      raise ArgumentError.new "Duplicate flag option '#{long}'" if @options.has_key? long

      if op = @options.values.find { |o| o.short == short }
        raise ArgumentError.new "Flag '#{op.long}' already has the short option '#{short}'"
      end

      @options[long] = Option.new(long, short, desc, required, has_value, default)
    end

    def execute(input : String | Array(String), *, parser : Parser? = nil) : Nil
      parser ||= Parser.new input
      results = parser.parse
      Executor.handle self, results
    end

    def pre_run(args : ArgsInput, options : OptionsInput) : Bool?
    end

    abstract def run(args : ArgsInput, options : OptionsInput) : Nil

    def post_run(args : ArgsInput, options : OptionsInput) : Nil
    end

    def on_error(ex : Exception)
      raise ex
    end

    def on_missing_arguments(args : Array(String))
      raise ArgumentError.new %(Missing required argument#{"s" if args.size > 1}: #{args.join(", ")})
    end

    def on_unknown_arguments(args : Array(String))
      raise ArgumentError.new %(Unknown argument#{"s" if args.size > 1}: #{args.join(", ")})
    end

    def on_missing_options(options : Array(String))
      raise ArgumentError.new %(Missing required option#{"s" if options.size > 1}: #{options.join(", ")})
    end

    def on_unknown_options(options : Array(String))
      raise ArgumentError.new %(Unknown option#{"s" if options.size > 1}: #{options.join(", ")})
    end
  end
end
