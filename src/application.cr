module CLI
  class Application
    property? parse_string_input : Bool
    property string_delimiters : Array(Char)
    property option_delimiter : Char

    property header : String?
    property description : String?
    property footer : String?
    property version : String?
    property commands : Hash(String, Command)
    @default : String?

    def initialize(*, @parse_string_input = true, @string_delimiters = ['"', '\''],
                   @option_delimiter = '-', @header = nil, @description = nil,
                   @footer = nil, @help_template = nil)
      @commands = {} of String => Command
    end

    def run(input : String | Array(String)) : Nil
      parser = Parser.new(
        @parse_string_input,
        @string_delimiters,
        @option_delimiter
      )
      results = parser.parse input

      needs_help = results.values.any? { |a| a[:name].in?("h", "help") || a[:value] == "help" }
      if needs_help
        arg = results.values.select { |a| a[:kind] == :argument && a[:value] != "help" }.first?
        if arg
          if target = @commands[arg[:value].not_nil!]?
            puts target.help_template
            exit
          else
            if arg[:value] == "help"
              on_no_main_command
            else
              on_command_not_found arg[:value].not_nil!
            end
            exit 1
          end
        else
          on_no_main_command
          exit 1
        end
      end

      first_arg : ParsedArg? = nil
      results.each do |i, arg|
        if prev = results[i - 1]?
          next unless prev[:kind] == :argument
          first_arg = arg
          break
        else
          first_arg = arg
          break
        end
      end

      cmd : Command

      if arg = first_arg
        if found = @commands[arg[:value]]?
          cmd = found
          results.shift
          results = results.to_a.map { |(key, val)| {key - 1, val} }.to_h
        else
          if default = @default
            cmd = @commands[default]
          else
            on_command_not_found arg[:value] || arg[:name]
            exit 1
          end
        end
      else
        if default = @default
          cmd = @commands[default]
        else
          on_no_main_command
          exit 1
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

              if next_args.empty?
                raise "Missing argument for option '#{opt.to_s}'" unless opt.has_default?
                parsed_opts << opt
              else
                arg = parsed.delete next_args.keys.first
                opt.value = arg.not_nil![:value]
                parsed_opts << opt
              end
            end
          end
        else
          invalid_opts << option[:name]
        end
      end

      cmd.on_invalid_options(invalid_opts) unless invalid_opts.empty?

      default_opts = cmd.options.reject(&.in?(parsed_opts)).select(&.has_default?)
      parsed_opts += default_opts

      missing_opts = cmd.options.select(&.required?).reject(&.in?(parsed_opts))
      cmd.on_missing_options(missing_opts) unless missing_opts.empty?

      arguments = parsed.values.select { |a| a[:kind] == :argument }.each_with_index.to_h.invert
      parsed_args = {} of String => Argument
      missing_args = [] of Argument

      cmd.arguments.values.each_with_index do |argument, i|
        if arg = arguments[i]?
          argument.value = arg[:value]
          parsed_args[argument.name] = argument
        else
          missing_args << argument if argument.required?
        end
      end

      cmd.on_missing_arguments(missing_args) unless missing_args.empty?

      {ArgsInput.new(parsed_args), OptionsInput.new(parsed_opts)}
    end

    def add_command(command : Command.class, *, default : Bool = false) : Nil
      raise "A default command has already been set" if default && @default

      cmd = command.new self
      @default = cmd.name if default
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
          str << header << "\n\n"
        end

        if desc = @description
          str << desc << "\n\n"
        end

        unless @commands.empty?
          str << "Commands:"
          max_space = @commands.keys.map(&.size).max + 4

          @commands.each do |name, cmd|
            str << "\n\t" << name
            str << " " * (max_space - name.size)
            str << cmd.short_help
          end

          str << '\n'
        end

        if footer = @footer
          str << '\n' << footer
        end
      end

      template
    end

    def on_command_not_found(name : String) : Nil
      puts "Error: command '#{name}' not found\n\n"
      puts help_template
    end

    def on_no_main_command : Nil
      puts "Error: no main command has been set\n\n"
      puts help_template
    end
  end
end
