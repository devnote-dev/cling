module CLI
  class Application
    property? parse_string_input : Bool
    property string_delimiters : Array(Char)
    property option_delimiter : Char

    property header : String?
    property description : String?
    property footer : String?
    property version : String?
    property help_message : String?
    property commands : Hash(String, Command)

    def initialize(*, @parse_string_input = true, @string_delimiters = ['"', '\''],
                   @option_delimiter = '-', @header = nil, @description = nil,
                   @footer = nil, @help_message = nil, @help_template = nil)
      @commands = {} of String => Command
    end

    def run(input : String | Array(String)) : Nil
      parser = Parser.new(
        @parse_string_input,
        @string_delimiters,
        @option_delimiter
      )
      results = parser.parse input
      first_arg = results.select { |_, a| a[:kind] == :argument }.first_value?
      cmd : Command

      if arg = first_arg
        if found = @commands[arg[:value]]?
          cmd = found
        else
          if default = @default_command
            cmd = @commands[default]
          else
            raise "No default command has been set"
          end
        end
      else
        if default = @default_command
          cmd = @commands[default]
        else
          raise "No default command has been set"
        end
      end

      args, opts = validate cmd, results

      begin
        cmd.execute args, opts
      rescue ex
        cmd.on_error ex
      end
    end

    private def validate(cmd : Command, parsed : Hash(Int32, ParsedArg)) : {ArgsInput, OptionsInput}
      options = parsed.reject { |_, a| a[:kind] == :argument }
      parsed_opts = [] of Option
      invalid_opts = [] of String

      options.each do |i, option|
        if opt = cmd.options.find { |o| o.short == option[:name] || o.long == option[:name] }
          case opt.kind
          when .none?
            raise "Option '#{opt.to_s}' takes no arguments" if option[:value]
            parsed_opts << opt
          when .string?
            if value = option[:value]
              opt.value = value
              parsed_opts << opt
            else
              next_args = parsed
                .select { |k, _| k > i }
                .select { |_, a| a[:kind] == :argument }

              raise "Missing argument for option '#{opt.to_s}'" if next_args.empty?
              arg = parsed.delete next_args.keys.first
              opt.value = arg.not_nil![:value]
              parsed_opts << opt
            end
          end
        else
          invalid_opts << option[:name]
        end
      end

      cmd.on_invalid_options(invalid_opts) unless invalid_opts.empty?

      missing_opts = cmd.options.select(&.required?).reject(&.in?(parsed_opts))
      cmd.on_missing_options(missing_opts) unless missing_opts.empty?

      arguments = parsed.select { |_, a| a[:kind] == :argument }
      parsed_args = {} of String => Argument
      missing_args = [] of Argument

      cmd.arguments.values.each_with_index do |argument, i|
        if arg = arguments[i]?
          argument.value = arg[:value]
        else
          missing_args << argument if argument.required?
        end
      end

      cmd.on_missing_arguments(missing_args) unless missing_args.empty?

      {ArgsInput.new(parsed_args), OptionsInput.new(parsed_opts)}
    end

    def default_command : String?
      @default_command
    end

    def default_command=(name : String)
      raise "Unknown command '#{name}'" unless @commands.has_key? name
      @default_command = name
    end

    def add_command(command : Command.class) : Nil
      cmd = command.new self
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
