module CLI
  # Generates a formatted help template for command components.
  class Formatter
    # Represents options for the formatter.
    class Options
      # The character to use for flag option delimiters (default is `-`).
      property option_delim : Char

      # Whether to show the `default` tag for options with default values (default is `true`).
      property show_defaults : Bool

      # Whether to show the `required` tag for required arguments/options (default is `true`).
      property show_required : Bool

      def initialize(*, @option_delim : Char = '-', @show_defaults : Bool = true, @show_required : Bool = true)
      end
    end

    # :nodoc:
    property options : Options

    def initialize(@options : Options = Options.new)
    end

    # Generates a help template for the specified command. This will attempt to fill fields that
    # have not been set in the command, for example, command usage strings.
    def generate(command : Command) : String
      String.build do |str|
        if header = command.header
          str << header << "\n\n"
        end

        if description = command.description
          str << description << "\n\n"
        end

        str << "Usage:"
        if command.usage.empty?
          str << "\n\t" << command.name
          unless command.arguments.empty?
            if command.arguments.values.any? &.required?
              str << " <arguments>"
            else
              str << " [arguments]"
            end
          end

          unless command.options.empty?
            if command.options.values.any? &.required?
              str << " <options>"
            else
              str << " [options]"
            end
          end
        else
          command.usage.each do |use|
            str << "\n\t" << use
          end
        end
        str << "\n\n"

        unless command.children.empty?
          str << format_commands(command) << "\n\n"
        end
        unless command.arguments.empty?
          str << format_arguments(command) << "\n\n"
        end
        unless command.options.empty?
          str << format_options(command) << "\n\n"
        end

        if footer = command.footer
          str << '\n' << footer
        end
      end
    end

    # Returns a formatted string for subcommands (children) of the set command.
    def format_commands(command : Command) : String
      commands = command.children.values.reject &.hidden?
      return "" if commands.empty?

      String.build do |str|
        str << "Commands:"
        max_space = commands.map(&.name.size).max + 4

        commands.each do |command|
          str << "\n\t" << command.name
          str << " " * (max_space - command.name.size)
          str << command.summary
        end
      end
    end

    # Returns a formatted string for arguments in the set command.
    def format_arguments(command : Command) : String
      return "" if command.arguments.empty?

      String.build do |str|
        str << "Arguments:"
        max_space = command.arguments.keys.map(&.size).max + 4

        command.arguments.each do |name, argument|
          str << "\n\t" << name
          str << " " * (max_space - name.size)
          str << argument.description
          str << " (required)" if @options.show_required && argument.required?
        end
      end
    end

    # Returns a formatted string for options in the set command.
    def format_options(command : Command) : String
      return "" if command.options.empty?

      options = command.options.values

      String.build do |str|
        str << "Options:"
        max_space = options.map { |o| 2 + o.long.size + (o.short ? 2 : 0) }.max + 2

        delim = @options.option_delim.to_s * 2
        options.each do |option|
          name_size = 2 + option.long.size + (option.short ? 2 : -2)

          str << "\n\t"
          if short = option.short
            str << delim[0] << short << ", "
          end

          str << delim << option.long
          str << " " * (max_space - name_size)
          str << option.description
          str << " (required)" if @options.show_required && option.required?

          if @options.show_defaults
            if option.has_default? && (default = option.default.to_s) && !default.blank?
              str << " (default: " << default << ')'
            end
          end
        end
      end
    end
  end
end
