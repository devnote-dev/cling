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

    @help_template : String?
    @on_error : Exception ->
    @on_missing_args : Array(String) ->
    @on_unknown_args : Array(String) ->
    @on_missing_opts : Array(String) ->
    @on_unknown_opts : Array(String) ->

    def initialize(*, aliases : Array(String)? = nil, usage : Array(String)? = nil,
                   @header : String? = nil, @summary : String? = nil, @description : String? = nil,
                   @footer : String? = nil, @parent : Command? = nil, children : Array(Command)? = nil,
                   arguments : Array(Argument)? = nil, options : Array(Option)? = nil,
                   @hidden : Bool = false, @inherit_borders : Bool = true,
                   @inherit_options : Bool = true)
      @aliases = aliases || [] of String
      @usage = usage || [] of String
      @children = children || [] of Command
      @arguments = arguments || [] of Argument
      @options = options || [] of Option

      @on_error = ->(ex) { raise ex }

      @on_missing_args = ->(args) do
        raise %(Missing required argument#{"s" if args.size > 1}: #{args.join(", ")})
      end

      @on_unknown_args = ->(args) do
        raise %(Unknown argument#{"s" if args.size > 1}: #{args.join(", ")})
      end

      @on_missing_opts = ->(opts) do
        raise %(Missing required option#{"s" if opts.size > 1}: #{opts.join(", ")})
      end

      @on_unknown_opts = ->(opts) do
        raise %(Unknown option#{"s" if opts.size > 1}: #{opts.join(", ")})
      end
    end

    abstract def setup : Nil

    def name : String
      @name || raise "No name has been set for command"
    end

    def name=(@name : String)
    end

    def help_template : String
      @help_template
    end

    def help_template=(@help_template : String?)
    end

    def add_command(command : Command.class) : Nil
      cmd = command.new parent: self
      cmd.setup
      raise "Duplicate command '#{cmd.name}'" if @children.has_key? cmd.name

      if cmd.inherit_borders?
        cmd.header = @header
        cmd.footer = @footer
      end

      cmd.options += @options if cmd.inherit_options
      @children[cmd.name] = cmd
    end

    def add_commands(*commands : Command.class) : Nil
      commands.each { |c| add_command(c) }
    end

    def add_argument(name : String, *, desc : String? = nil, required : Bool = false) : Nil
      raise "Duplicate argument '#{name}'" if @arguments.has_key? name
      @arguments[name] = Argument.new(name, desc, required)
    end

    def add_option(long : String, *, desc : String? = nil, required : Bool = false,
                   default : Option::Value::Type = nil) : Nil
      raise "Duplicate flag option '#{long}'" if @options.has_key? long
      @options[long] = Option.new(long, nil, desc, required, default)
    end

    def add_option(short : Char, long : String, *, desc : String? = nil, required : Bool = false,
                   default : Option::Value::Type = nil) : Nil
      raise "Duplicate flag option '#{long}'" if @options.has_key? long

      if op = @options.find { |o| o.short == short }
        raise "Flag '#{op.long}' already has the short option '#{short}'"
      end

      @options[long] = Option.new(long, short, desc, required, default)
    end

    def execute(input : Array(String), *, parser : Parser? = nil) : Nil
      parser ||= Parser.new(input, Parser::Options.new)
      results = parser.parse
      # Executor.new(self).handle(results)
    end

    def pre_run(args, options) : Nil
    end

    abstract def run(args, options) : Nil

    def post_run(args, options) : Nil
    end

    def on_error(&block : Exception ->)
      @on_error = block
    end

    def on_missing_arguments(&block : Array(String) ->)
      @on_missing_args = block
    end

    def on_unknown_arguments(&block : Array(String) ->)
      @on_unknown_args = block
    end

    def on_missing_options(&block : Array(String) ->)
      @on_missing_opts = block
    end

    def on_unknown_options(&block : Array(String) ->)
      @on_missing_opts = block
    end
  end
end
