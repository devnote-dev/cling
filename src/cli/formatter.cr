module CLI
  class Formatter
    struct Options
    end

    property command : Command
    property options : Options

    def initialize(@command : Command, @options : Options)
    end

    def generate_template : String
      String.build do |str|
        if header = @command.header
          str << header << "\n\n"
        end

        if desc = @command.description
          str << desc << "\n\n"
        end

        str << "Usage:"
        if @command.usage.empty?
          str << "\n\t" << @command.name
          unless @command.arguments.empty?
            if @command.arguments.values.any? &.required?
              str << " <arguments>"
            else
              str << " [arguments]"
            end
          end

          unless @command.options.empty?
            if @command.options.values.any? &.required?
              str << " <options>"
            else
              str << " [options]"
            end
          end
        else
          @command.usage.each do |use|
            str << "\n\t" << use
          end
        end
        str << "\n\n"

        unless @command.children.empty?
          str << format_commands << "\n\n"
        end
        unless @command.arguments.empty?
          str << format_arguments << "\n\n"
        end
        unless @command.options.empty?
          str << format_options << "\n\n"
        end

        if footer = @command.footer
          str << '\n' << footer
        end
      end
    end

    def format_commands : String
      commands = @command.children.values.reject &.hidden?
      return "" if commands.empty?

      String.build do |str|
        str << "Commands:"
        max_space = commands.map(&.name.size).max + 4

        commands.each do |cmd|
          str << "\n\t" << cmd.name
          str << " " * (max_space - cmd.name.size)
          str << cmd.summary
        end
      end
    end

    def format_arguments : String
      return "" if @command.arguments.empty?

      String.build do |str|
        str << "Arguments:"
        max_space = @command.arguments.keys.map(&.size).max + 4

        @command.arguments.each do |name, arg|
          str << "\n\t" << name
          str << " " * (max_space - name.size)
          str << arg.description
          str << " (required)" if arg.required?
        end
      end
    end

    def format_options : String
      return "" if @command.options.empty?

      options = @command.options.values

      String.build do |str|
        str << "Options:"
        max_space = options.map { |o| 2 + o.long.size + (o.short ? 2 : 0) }.max + 2

        delim = "-" # TODO: change this to match config
        options.each do |opt|
          name_size = 2 + opt.long.size + (opt.short ? 2 : -2)

          str << "\n\t"
          if short = opt.short
            str << delim << short << ", "
          end

          str << (delim * 2) << opt.long
          str << " " * (max_space - name_size)
          str << opt.description

          if opt.has_default? && (default = opt.default.to_s) && !default.blank?
            str << " (default: " << default << ')'
          end
        end
      end
    end
  end
end
