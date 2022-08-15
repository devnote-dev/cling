module CLI
  class Application
    property? allow_long_short : Bool
    property? allow_short_long : Bool
    property? parse_string_input : Bool
    property string_delimiters : Array(Char)
    property option_delimiter : Char

    property header : String?
    property description : String?
    property footer : String?
    property version : String?
    property help_message : String?
    property commands : Hash(String, Command)

    def initialize(*, @allow_long_short = false, @allow_short_long = false,
                   @parse_string_input = true, @string_delimiters = ['"', '\''],
                   @option_delimiter = '-', @header = nil, @description = nil,
                   @footer = nil, @help_message = nil, @help_template = nil)
      @commands = {} of String => Command
    end

    def run(input : String | Array(String)) : Nil
      parser = Parser.new(
        @allow_short_long,
        @allow_long_short,
        @parse_string_input,
        @string_delimiters,
        @option_delimiter
      )
      results = parser.parse input

      args, options = results.partition { |a| a[:kind] == :argument }
      cmd : Command

      unless args.empty?
        if found = @commands[args[0][:value]]?
          cmd = found
        elsif default = @default_command
          cmd = @commands[default]
        else
          raise "no command has been set to handle input"
        end
      else
        unless default = @default_command
          raise "No default command has been set to run"
        end

        cmd = @commands[default]
      end

      cmd.setup
      parsed_args, parsed_opts = validate cmd, args, options

      begin
        cmd.execute parsed_args, parsed_opts
      rescue ex
        cmd.on_error ex
      end
    end

    private def validate(cmd : Command,
                         args : MappedArgs,
                         options : MappedArgs) : {ArgsInput, OptionsInput}
      parsed_args = {} of String => Argument
      invalid_args = [] of String

      valid_args = args[...cmd.arguments.values.select(&.required?).size]
      invalid_args = args.reject(&.in?(valid_args)).map(&.[:value].not_nil!)
      cmd.on_invalid_arguments(invalid_args) unless invalid_args.empty?

      cmd.arguments.each.with_index do |(name, arg), index|
        if raw = args[index]?
          arg.value = raw[:value]
          parsed_args[name] = arg
        else
          break
        end
      end

      parsed_opts = [] of Option
      invalid_opts = [] of String

      options.each do |raw|
        if raw[:kind] == :short
          if opt = cmd.options.find { |o| o.short == raw[:name] }
            opt.value = raw[:value]
            parsed_opts << opt
          else
            invalid_opts << raw[:name]
          end
        else
          if opt = cmd.options.find { |o| o.long == raw[:name] }
            opt.value = raw[:value]
            parsed_opts << opt
          else
            invalid_opts << raw[:name]
          end
        end
      end
      cmd.on_invalid_options(invalid_opts) unless invalid_opts.empty?

      missing_args = cmd.arguments.reject(&.in?(parsed_args)).values
      cmd.on_missing_arguments(missing_args) unless missing_args.empty?

      missing_opts = cmd.options.reject &.in?(parsed_opts)
      cmd.on_missing_options(missing_opts) unless missing_opts.empty?

      {ArgsInput.new(parsed_args), OptionsInput.new(parsed_opts)}
    end

    def default_command : String?
      @default_command
    end

    def default_command=(name : String)
      raise "Unknown command '#{name}'" unless @commands.has_key? name
      @default_command = name
    end

    def add_command(cmd : Command) : Nil
      @commands[cmd.name.not_nil!] = cmd
    end

    def help_template : String
      @help_template || generate_help_template
    end

    def help_template=(@help_template : String?)
    end

    private def generate_help_template : String
      template = String.build do |str|
        if header = @header
          str << header << '\n'
          str << '\n' if @description
        end
        if desc = @description
          str << desc << '\n'
          str << '\n' unless @commands.empty?
        end

        unless @commands.empty?
          str << "Commands:\n"
          max_space = @commands.sum(1) { |c| c.name.size }

          @commands.each do |cmd|
            str << '\t' << cmd.name
            str << ' ' * (max_size - cmd.name.size)
            str << cmd.short_help << '\n'
          end

          str << '\n'
        end
      end

      template
    end
  end
end
