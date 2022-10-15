module CLI::Executor
  private struct Result
    getter parsed_opts : OptionsInput
    getter unknown_opts : Array(String)
    getter missing_opts : Array(String)
    getter parsed_args : ArgsInput
    getter unknown_args : Array(String)
    getter missing_args : Array(String)

    def initialize(parsed_opts, @unknown_opts, @missing_opts, parsed_args, @unknown_args, @missing_args)
      @parsed_opts = OptionsInput.new parsed_opts
      @parsed_args = ArgsInput.new parsed_args
    end
  end

  def self.handle(command : Command, results : Hash(Int32, Parser::Result)) : Nil
    results, pos = get_in_position command, results
    cmd = resolve_command command, pos
    raise NotFoundError.new unless cmd

    begin
      res = cmd.pre_run results.parsed_args, results.parsed_opts
      unless res.nil?
        return unless res
      end
    rescue ex
      cmd.on_error ex
    end

    finalize cmd, results

    begin
      cmd.run results.parsed_args, results.parsed_opts
      cmd.post_run results.parsed_args, results.parsed_opts
    rescue ex
      cmd.on_error ex
    end
  end

  def self.resolve_command(command : Command, args : Hash(Int32, Parser::Result)) : Command?
    full_args = args.select { |_, v| v.kind.argument? && !v.string? }
    return command if full_args.empty? || command.children.empty?

    key, res = full_args.first
    if cmd = command.children.values.find &.is?(res.value)
      args.delete key
      resolve_command cmd, args
    elsif !command.arguments.empty?
      command
    else
      nil
    end
  end

  private def self.get_in_position(command : Command, results : Hash(Int32, Parser::Result)) : {Result, Hash(Int32, Parser::Result)}
    options = results.reject { |_, v| v.kind.argument? }
    parsed_opts = {} of String => Option
    unknown_opts = [] of String

    options.each do |i, res|
      if opt = command.options.values.find &.is? res.parse_value
        if opt.has_value?
          if res.value.includes? '='
            opt.value = Value.new res.value.split('=', 2).last
            parsed_opts[opt.long] = opt
          else
            if arg = results[i + 1]?
              if arg.kind.argument?
                opt.value = Value.new arg.value
                parsed_opts[opt.long] = opt
                results.delete(i + 1)
                next
              end
            end

            raise ArgumentError.new "Missing argument for option '#{opt}'" unless opt.has_default?
            opt.value = Value.new opt.default
            parsed_opts[opt.long] = opt
          end
        else
          raise ArgumentError.new "Option '#{opt}' takes no arguments" if res.value.includes? '='
          parsed_opts[opt.long] = opt
        end
      else
        unknown_opts << res.parse_value
      end
    end

    default_opts = command.options
      .select { |_, v| v.has_default? }
      .reject { |k, _| parsed_opts.has_key?(k) }

    parsed_opts.merge! default_opts
    missing_opts = command.options
      .select { |_, v| v.required? }
      .keys
      .reject { |k| parsed_opts.has_key?(k) }

    arguments = results.values.select { |v| v.kind.argument? }
    parsed_args = {} of String => Argument
    missing_args = [] of String

    command.arguments.values.each_with_index do |arg, i|
      if res = arguments[i]?
        arg.value = Value.new res.value
        parsed_args[arg.name] = arg
        results.delete i
      else
        missing_args << arg.name if arg.required?
      end
    end

    unknown_args = if arguments.empty?
        [] of String
      else
        arguments[parsed_args.size...].map &.value
      end

    {Result.new(parsed_opts, unknown_opts, missing_opts, parsed_args, unknown_args, missing_args), results}
  end

  private def self.finalize(command : Command, res : Result) : Nil
    command.on_unknown_options(res.unknown_opts) unless res.unknown_opts.empty?
    command.on_missing_options(res.missing_opts) unless res.missing_opts.empty?
    command.on_missing_arguments(res.missing_args) unless res.missing_args.empty?
    command.on_unknown_arguments(res.unknown_args) unless res.unknown_args.empty?
  end
end
