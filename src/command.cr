module CLI
  abstract class Command
    @name : String
    property aliases : Array(String)
    property usage : Array(String)
    property header : String?
    property summary : String?
    property description : String?
    property line_fold : Int32
    property footer : String?
    @help_template : String
    property arguments : Array(Argument)
    property options : Array(Option)
    property inherit_options : Bool

    def initialize
      @aliases = [] of String
      @usage = [] of String
      @line_fold = 70
      @arguments = [] of Argument
      @options = [] of Option
      @inherit_options = false
    end

    def name : String
      @name || raise "No name has been set for command"
    end

    def name=(@name : String)
    end

    def help_template : String
      if tmpl = @help_template
        tmpl = tmpl.gsub "$header", @header
        tmpl = tmpl.gsub "$name", @name
        tmpl = tmpl.gsub "$description", @description
        tmpl.gsub "$footer", @footer
      else
        generate_help_template
      end
    end

    def help_template=(@help_template : String?)
    end

    private def generate_help_template : String
      template = String.build do |str|
        if header = @header
          str << header << "\n\n"
        end

        if desc = @description
          if desc.size > @line_fold
            value = String.build do |v|
              count = 0
              desc.split.each do |word|
                count += word.size + 1
                if count > @line_fold
                  v << '\n'
                  count = word.size + 1
                end

                v << word << ' '
              end
            end.strip

            str << value << "\n\n"
          else
            str << desc << "\n\n"
          end
        end

        str << "Usage:"
        if @usage.empty?
          str << "\n\t" << @name

          unless @arguments.empty?
            if @arguments.values.any? &.required?
              str << " <arguments>"
            else
              str << " [arguments]"
            end
          end

          unless @options.empty?
            if @options.any? &.required?
              str << " <options>"
            else
              str << " [options]"
            end
          end
        else
          @usage.each do |use|
            str << "\n\t" << use
          end
        end

        str << "\n\n"

        unless @subcommands.empty?
          str << "Commands:"
          max_space = @subcommands.keys.map(&.size).max + 4

          @subcommands.each do |name, cmd|
            str << "\n\t" << name
            if short = cmd.short_help
              str << " " * (max_space - name.size)
              str << short
            end
          end

          str << '\n'
        end

        unless @arguments.empty?
          str << "Arguments:"
          max_space = @arguments.keys.map(&.size).max + 4

          @arguments.each do |name, arg|
            str << "\n\t" << name
            if sum = arg.summary
              str << " " * (max_space - name.size)
              str << sum
            end
          end

          str << "\n\n"
        end

        unless @options.empty?
          str << "Options:"
          max_space = @options.map { |o| o.long.size + (o.short ? 2 : 0) + 2 }.max + 2

          @options.each do |opt|
            name_size = opt.long.size + (opt.short ? 2 : -2)

            str << "\n\t"
            if short = opt.short
              str << '-' << short << ", "
            end

            str << "--" << opt.long
            if desc = opt.description
              str << " " * (max_space - name_size)
              str << desc

              if opt.has_default? && (default = opt.default)
                str << " (default: " << default.unwrap_value << ')'
              end
            end

            str << '\n'
          end
        end

        if footer = @footer
          str << '\n' << footer
        end
      end

      template
    end

    def add_argument(name : String, *, desc : String? = nil, required : Bool = false) : Nil
      raise "Duplicate argument '#{name}'" if @arguments.has_key? name
      @arguments[name] = Argument.new(name, desc, required)
    end

    def add_option(long : String, *, desc : String? = nil, required : Bool = false,
                   default = nil) : Nil
      raise "Duplicate option '#{long}'" if @options.has_key? long
      @options[long] = Option.new(long, nil, desc, required, default)
    end

    def add_option(short : Char, long : String, *, desc : String? = nil,
                   required : Bool, default = nil) : Nil
      raise "Duplicate option '#{short}'" if @options.values.find { |o| o.short == short }
      raise "Duplicate option '#{long}'" if @options.has_key? long

      @options[long] = Option.new(long, short.to_s, desc, required, default)
    end

    def setup : Nil
      @name || raise "No name has been set for command"
    end

    def pre_hook(args, options) : Nil
    end

    abstract def execute(args, options) : Nil

    def post_hook(args, options) : Nil
    end

    def on_error(ex : Exception) : NoReturn
      raise ex
    end

    def on_missing_arguments(args : Array(String)) : NoReturn
      raise "Missing required argument#{"s" if args.size != 1}: #{args.join(", ")}"
    end

    def on_unknown_arguments(args : Array(String)) : NoReturn
      raise "Unknown argument#{"s" if args.size != 1}: #{args.join(", ")}"
    end

    def on_missing_options(options : Array(String)) : NoReturn
      raise "Missing required option#{"s" if options.size != 1}: #{options.join(", ")}"
    end

    def on_unknown_options(options : Array(String)) : NoReturn
      raise "Unknown option#{"s" if options.size != 1}: #{options.join(", ")}"
    end
  end
end
