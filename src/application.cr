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
    @help_template : String?

    property commands : Hash(String, Command)
    property default_command : String?

    def initialize(*, @allow_long_short = false, @allow_short_long = false,
                   @parse_string_input = true, @string_delimiters = ['"', '\''],
                   @option_delimiter = '-', @header, @description, @footer,
                   @help_message, @help_template)
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
      parsed_args, parsed_options = validate cmd, args, options

      begin
        cmd.execute parsed_args, parsed_options
      rescue ex
        cmd.on_error ex
      end
    end

    private def validate(cmd : Command,
                         args : MappedArgs,
                         options : MappedArgs) : {ArgsInput, OptionsInput}
      parsed_args = {} of String => Argument
      parsed_options = [] of Option

      # TODO
    end

    def help_template : String
      @help_template || generate_help_template
    end

    def help_template=(@help_template)
    end

    private def generate_help_template : String
      template = String.build do |str|
        if header = @header
          str << header << '\n'
        end
        if desc = @description
          str << desc << '\n'
        end

        unless @commands.empty?
          str << "Commands:\n"
          max_space = @commands.sum(1) &.name.size

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
