module CLI
  class Executor
    getter main : Command

    def initialize(@main)
    end

    def handle(results : Hash(Int32, Parser::Result)) : Nil
      args = results.select { |_, v| v.kind.argument? && !v.string? }
      unless cmd = resolve_command @main, args
        raise "Command Not Found"
      end

      res, opts = get_options_in_position cmd, results
      args = get_args_in_position cmd, res

      begin
        cmd.pre_run args, opts
        cmd.run args, opts
        cmd.post_run args, opts
      rescue ex
        cmd.on_error.call ex
      end
    end

    def resolve_command(command : Command, args : Hash(Int32, Parser::Result)) : Command?
      return command if command.children.empty? || args.empty?
      if cmd = command.children[args.first[1].value]?
        args.shift
        resolve_command cmd, args
      end
    end

    def get_options_in_position(
      command : Command,
      results : Hash(Int32, Parser::Result)
    ) : {Hash(Int32, Parser::Result), OptionsInput}
      options = results.reject { |_, v| v.kind.argument? }
      parsed_opts = {} of String => Option
      unknown_opts = [] of String

      options.each do |i, res|
        if opt = command.options.values.find &.is? res.parse_value
          if opt.has_value?
            if res.value.includes? '='
              opt.value = Option::Value.new res.value.split('=', 2).last
              parsed_opts[opt.long] = opt
            else
              next_args = results
                .select { |k, _| k > i }
                .select { |_, v| v.kind.argument? }

              if next_args.empty?
                # should call invalid_opts but it's not implemented yet
                raise "Missing argument for option '#{opt}'" unless opt.has_default?
                opt.value = Option::Value.new opt.default
                parsed_opts[opt.long] = opt
              else
                arg = next_args.first
                results.delete arg[0]
                opt.value = Option::Value.new arg[1].value
                parsed_opts[opt.long] = opt
              end
            end
          else
            raise "Option '#{opt}' takes no arguments" if res.value.includes? '='
            parsed_opts[opt.long] = opt
          end
        else
          unknown_opts << res.parse_value
        end
      end

      command.on_unknown_opts.call(unknown_opts) unless unknown_opts.empty?
      default_opts = command.options
        .select { |_, v| v.has_default? }
        .reject { |k, _| parsed_opts.has_key?(k) }

      parsed_opts.merge! default_opts
      missing_opts = command.options
        .select { |_, v| v.required? }
        .keys
        .reject { |k| parsed_opts.has_key?(k) }

      command.on_missing_opts.call(missing_opts) unless missing_opts.empty?

      {results, OptionsInput.new(parsed_opts)}
    end

    def get_args_in_position(
      command : Command,
      results : Hash(Int32, Parser::Result)
    ) : ArgsInput
      arguments = results.values.select { |v| v.kind.argument? }
      parsed_args = {} of String => Argument
      missing_args = [] of String

      command.arguments.values.each_with_index do |arg, i|
        if res = arguments[i]?
          arg.value = res.value
          parsed_args[arg.name] = arg
        else
          missing_args << arg.name if arg.required?
        end
      end

      command.on_missing_args.call(missing_args) unless missing_args.empty?
      unknown_args = arguments[command.arguments.size...].map &.value
      command.on_unknown_args.call(unknown_args) unless unknown_args.empty?

      ArgsInput.new parsed_args
    end
  end
end
