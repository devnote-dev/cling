module Cling
  # Generates a formatted help template for command components.
  class Formatter
    # Represents options for the formatter.
    class Options
      # The character to use for flag option delimiters (default is `-`).
      property option_delim : Char

      # Whether to show the `default` tag for options with default values (default is `true`).
      property? show_defaults : Bool

      # Whether to show the `required` tag for required arguments/options (default is `true`).
      property? show_required : Bool

      def initialize(*, @option_delim : Char = '-', @show_defaults : Bool = true,
                     @show_required : Bool = true)
      end
    end

    # :nodoc:
    property options : Options

    def initialize(@options : Options = Options.new)
    end

    # Generates a help template for the specified command. This will attempt to fill fields that
    # have not been set in the command, for example, command usage strings. Values that are not
    # set, such as arguments and options, will not be written to the IO.
    def generate(command : Command) : String
      String.build do |io|
        format_header(command, io)
        format_description(command, io)
        format_usage(command, io)
        format_commands(command, io)
        format_arguments(command, io)
        format_options(command, io)
        format_footer(command, io)
      end.chomp
    end

    # :ditto:
    #
    # Writes to the IO and returns nothing.
    def generate(command : Command, io : IO) : Nil
      io << generate command
    end

    # Formats the header of a command into the given IO.
    def format_header(command : Command, io : IO) : Nil
      return unless header = command.header
      io << header << "\n\n"
    end

    # Formats the description of a command into the given IO.
    def format_description(command : Command, io : IO) : Nil
      return unless description = command.description
      io << description << "\n\n"
    end

    # Formats the usage strings of a command into the given IO.
    def format_usage(command : Command, io : IO) : Nil
      io << "Usage:"

      if command.usage.empty?
        io << "\n\t" << command.name
        unless command.arguments.empty?
          if command.arguments.values.any? &.required?
            io << " <arguments>"
          else
            io << " [arguments]"
          end
        end

        unless command.options.empty?
          if command.options.values.any? &.required?
            io << " <options>"
          else
            io << " [options]"
          end
        end
      else
        command.usage.each do |use|
          io << "\n\t" << use
        end
      end

      io << "\n\n"
    end

    # Formats the command information including subcommands into the given IO. By default, this
    # does not include hidden commands, but you can override this if you wish.
    def format_commands(command : Command, io : IO) : Nil
      commands = command.children.values.reject &.hidden?
      return if commands.empty?
      max_space = 4 + commands.max_of &.name.size

      io << "Commands:"
      commands.each do |cmd|
        io << "\n\t"
        if summary = command.summary
          cmd.name.ljust(io, max_space, ' ')
          io << summary
        else
          io << cmd.name
        end
      end

      io << "\n\n"
    end

    # Formats the arguments of the command into the given IO.
    def format_arguments(command : Command, io : IO) : Nil
      return if command.arguments.empty?
      max_space = 4 + command.arguments.keys.max_of &.size

      io << "Arguments:"
      command.arguments.each do |name, argument|
        io << "\n\t"
        name.ljust(io, max_space, ' ')
        io << argument.description
        io << " (required)" if @options.show_required? && argument.required?
      end

      io << "\n\n"
    end

    # Formats the options of the command into the given IO.
    def format_options(command : Command, io : IO) : Nil
      return if command.options.empty?

      delim = @options.option_delim
      max_space = 4 + command.options.values.max_of { |o| o.long.size + (o.short ? 6 : 4) }

      io << "Options:"
      command.options.each do |name, option|
        io << "\n\t"
        if option.short
          "#{delim}#{option.short}, #{delim}#{delim}#{name}".ljust(io, max_space, ' ')
        else
          "#{delim}#{delim}#{name}".ljust(io, max_space, ' ')
        end

        io << option.description
        io << " (required)" if @options.show_required? && option.required?

        if @options.show_defaults? && option.has_default?
          default = option.default.to_s
          next if default.blank?
          io << " (default: " << default << ')'
        end
      end

      io << "\n\n"
    end

    # Formats the footer of the command into the given IO.
    def format_footer(command : Command, io : IO) : Nil
      return unless footer = command.footer
      io << footer << "\n\n"
    end
  end
end
