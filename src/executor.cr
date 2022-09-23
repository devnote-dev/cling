module CLI::Executor
  def self.handle(command : Command, results : Hash(Int32, Parser::Result)) : Nil
    cmd, raw = resolve_command command, results
    raise "Command not found" unless cmd

    args, opts = get_in_position cmd, raw
    begin
      cmd.pre_run args, opts
      cmd.run args, opts
      cmd.post_run args, opts
    rescue ex
      cmd.on_error.call ex
    end
  end

  def self.resolve_command(
    command : Command,
    args : Hash(Int32, Parser::Result)
  ) : {Command?, Hash(Int32, Parser::Result)}
    full_args = args.select { |_, v| v.kind.argument? && !v.string? }
    return {command, args} if full_args.empty?
    return {command, args} if command.children.empty?
    if cmd = command.children[full_args.first[1].value]?
      args.delete full_args.first[0]
      resolve_command cmd, args
    else
      {nil, args}
    end
  end

  private def self.get_in_position(
    command : Command,
    results : Hash(Int32, Parser::Result)
  ) : {ArgsInput, OptionsInput}
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
              raise ArgumentError.new "Missing argument for option '#{opt}'" unless opt.has_default?
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
          raise ArgumentError.new "Option '#{opt}' takes no arguments" if res.value.includes? '='
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

    {ArgsInput.new(parsed_args), OptionsInput.new(parsed_opts)}
  end
end
