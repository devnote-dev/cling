module Cling
  abstract class Command
    # A set of aliases for the command.
    getter aliases : Set(String)

    # An array of usage strings to display in generated help templates.
    getter usage : Array(String)

    # A header message to display at the top of generated help templates.
    property header : String?

    # The summary of the command to show in generated help templates.
    property summary : String?

    # The description of the command to show for specific help with the command.
    property description : String?

    # A footer message to display at the bottom of generated help templates.
    property footer : String?

    # The parent of the command of which the current command inherits from.
    property parent : Command?

    # A hash of commands that belong and inherit from the parent command.
    getter children : Hash(String, Command)

    # A hash of arguments belonging to the command. These arguments are parsed at execution time
    # and can be accessed in the `pre_run`, `run`, and `post_run` methods via `ArgumentsInput`.
    getter arguments : Hash(String, Argument)

    # A hash of flag options belonging to the command. These options are parsed at execution time
    # and can be accessed in the `pre_run`, `run`, and `post_run` methods via `OptionsInput`.
    getter options : Hash(String, Option)

    # Whether the command should be hidden from generated help templates.
    property? hidden : Bool

    # Whether the command should inherit the `header` and `footer` strings from the parent command.
    property? inherit_borders : Bool

    # Whether the command should inherit the options from the parent command.
    property? inherit_options : Bool

    # Whether the command should inherit the IO streams from the parent command.
    property? inherit_streams : Bool

    # The standard input stream for commands (defaults to `STDIN`). This is a helper method for
    # custom commands and is only used by the `MainCommand` helper class.
    property stdin : IO

    # The standard output stream for commands (defaults to `STDOUT`). This is a helper method for
    # custom commands and is only used by the `MainCommand` helper class.
    property stdout : IO

    # The standard error stream for commands (defaults to `STDERR`). This is a helper method for
    # custom commands and is only used by the `MainCommand` helper class.
    property stderr : IO

    def initialize(*, aliases : Set(String)? = nil, usage : Array(String)? = nil,
                   @header : String? = nil, @summary : String? = nil, @description : String? = nil,
                   @footer : String? = nil, @parent : Command? = nil, children : Array(Command)? = nil,
                   arguments : Hash(String, Argument)? = nil, options : Hash(String, Option)? = nil,
                   @hidden : Bool = false, @inherit_borders : Bool = false, @inherit_options : Bool = false,
                   @inherit_streams : Bool = false, @stdin : IO = STDIN, @stdout : IO = STDOUT, @stderr : IO = STDERR)
      @name = ""
      @aliases = aliases || Set(String).new
      @usage = usage || [] of String
      @children = children || {} of String => Command
      @arguments = arguments || {} of String => Argument
      @options = options || {} of String => Option

      setup
    end

    # The name of the command. This is the only required field of a command and cannot be empty or
    # blank.
    def name : String
      raise CommandError.new "Command name cannot be empty" if @name.empty?
      raise CommandError.new "Command name cannot be blank" if @name.blank?

      @name
    end

    def name=(@name : String)
    end

    # An abstract method that should define information about the command such as the name,
    # aliases, arguments, options, etc. The command name is required for all commands, all other
    # values are optional including the help message.
    abstract def setup : Nil

    # Returns `true` if the argument matches the command name or any aliases.
    def is?(name : String) : Bool
      @name == name || @aliases.includes? name
    end

    # Returns the help template for this command. By default, one is generated interally unless
    # this method is overridden.
    def help_template : String
      Formatter.new.generate self
    end

    # Adds an alias to the command.
    def add_alias(name : String) : Nil
      @aliases << name
    end

    # Adds several aliases to the command.
    def add_aliases(*names : String) : Nil
      @aliases.concat names
    end

    # Adds a usage string to the command.
    def add_usage(usage : String) : Nil
      @usage << usage
    end

    # Adds a command as a subcommand to the parent. The command can then be referenced by
    # specifying it as the first argument in the command line.
    def add_command(command : Command) : Nil
      raise CommandError.new "Duplicate command '#{command.name}'" if @children.has_key? command.name
      command.aliases.each do |a|
        raise CommandError.new "Duplicate command alias '#{a}'" if @children.values.any? &.is? a
      end

      command.parent = self
      if command.inherit_borders?
        command.header = @header
        command.footer = @footer
      end

      command.options.merge! @options if command.inherit_options?

      if command.inherit_streams?
        command.stdin = @stdin
        command.stdout = @stdout
        command.stderr = @stderr
      end

      @children[command.name] = command
    end

    # Adds several commands as subcommands to the parent (see `add_command`).
    def add_commands(*commands : Command) : Nil
      commands.each { |c| add_command(c) }
    end

    # Adds an argument to the command.
    def add_argument(name : String, *, description : String? = nil, required : Bool = false,
                     multiple : Bool = false) : Nil
      raise CommandError.new "Duplicate argument '#{name}'" if @arguments.has_key? name
      if multiple && @arguments.values.find &.multiple?
        raise CommandError.new "Cannot have more than one argument with multiple values"
      end

      @arguments[name] = Argument.new(name, description, required, multiple)
    end

    # Adds a long flag option to the command.
    def add_option(long : String, *, description : String? = nil, required : Bool = false,
                   type : Option::Type = :none, default : Value::Type = nil) : Nil
      raise CommandError.new "Duplicate flag option '#{long}'" if @options.has_key? long

      @options[long] = Option.new(long, nil, description, required, type, default)
    end

    # Adds a short flag option to the command.
    def add_option(short : Char, long : String, *, description : String? = nil, required : Bool = false,
                   type : Option::Type = :none, default : Value::Type = nil) : Nil
      raise CommandError.new "Duplicate flag option '#{long}'" if @options.has_key? long
      if op = @options.values.find { |o| o.short == short }
        raise CommandError.new "Flag '#{op.long}' already has the short option '#{short}'"
      end

      @options[long] = Option.new(long, short, description, required, type, default)
    end

    # Executes the command with the given input and parser (see `Parser`).
    def execute(input : String | Array(String), *, parser : Parser? = nil) : Nil
      parser ||= Parser.new input
      results = parser.parse
      Executor.handle self, results
    end

    # A hook method to run once the command/subcommands, arguments and options have been parsed.
    # This has access to the parsed arguments and options from the command line. This is useful if
    # you want to implement checks for specific flags outside of the main `run` method, such as
    # `-v`/`--version` flags or `-h`/`--help` flags.
    #
    # Accepts a `Bool` or `nil` argument as a return to specify whether the command should continue
    # to run once finished (`true` or `nil` to continue, `false` to stop).
    def pre_run(arguments : Arguments, options : Options) : Bool?
    end

    # The main point of execution for the command, where arguments and options can be accessed.
    abstract def run(arguments : Arguments, options : Options) : Nil

    # A hook method to run once the `pre_run` and main `run` methods have been executed.
    def post_run(arguments : Arguments, options : Options) : Nil
    end

    # A hook method for when the command raises an exception during execution. By default, this
    # raises the exception.
    def on_error(ex : Exception)
      raise ex
    end

    # A hook method for when the command receives missing arguments during execution. By default,
    # this raises an `ArgumentError`.
    def on_missing_arguments(arguments : Array(String))
      raise CommandError.new %(Missing required argument#{"s" if arguments.size > 1}: #{arguments.join(", ")})
    end

    # A hook method for when the command receives unknown arguments during execution. By default,
    # this raises an `ArgumentError`.
    def on_unknown_arguments(arguments : Array(String))
      raise CommandError.new %(Unknown argument#{"s" if arguments.size > 1}: #{arguments.join(", ")})
    end

    # A hook method for when the command receives missing options that are required during
    # execution. By default, this raises an `ArgumentError`.
    def on_missing_options(options : Array(String))
      raise CommandError.new %(Missing required option#{"s" if options.size > 1}: #{options.join(", ")})
    end

    # A hook method for when the command receives unknown options during execution. By default,
    # this raises an `ArgumentError`.
    def on_unknown_options(options : Array(String))
      raise CommandError.new %(Unknown option#{"s" if options.size > 1}: #{options.join(", ")})
    end
  end
end
