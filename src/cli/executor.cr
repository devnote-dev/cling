# Handles the execution of commands. In most cases you should never need to interact with this
# module as the `Command#execute` method is the main entrypoint for executing commands. For this
# reason, most of the modules methods are hidden.
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

  # Handles the execution of a command using the given results from the parser.
  #
  # ### Process
  #
  # 1. The command is resolved first using a pointer to the results to prevent having to deal with
  # multiple copies of the same object, and is mutated in the `resolve_command` method.
  #
  # 2. The results are evaluated with the command arguments and options to set their values and
  # move the missing, unknown and invalid arguments/options into place.
  #
  # 3. The `Command#pre_run` hook is executed with the resolved arguments and options, and the
  # response is checked for continuation.
  #
  # 4. The evaluated arguments and options are finalized: missing, unknown and invalid arguments/
  # options trigger the necessary missing/unknown/invalid command hooks.
  #
  # 5. The main `Command#run` and `Command#post_run` methods are executed with the evaluated
  # arguments and options.
  def self.handle(command : Command, results : Hash(Int32, Parser::Result)) : Nil
    cmd = resolve_command command, pointerof(results)
    raise CommandError.new "Command '#{results.keys.first}' not found" unless cmd

    executed = get_in_position command, results

    begin
      res = cmd.pre_run executed.parsed_args, executed.parsed_opts
      unless res.nil?
        return unless res
      end
    rescue ex
      cmd.on_error ex
    end

    finalize cmd, executed

    begin
      cmd.run executed.parsed_args, executed.parsed_opts
      cmd.post_run executed.parsed_args, executed.parsed_opts
    rescue ex
      cmd.on_error ex
    end
  end

  private def self.resolve_command(command : Command, args : Hash(Int32, Parser::Result)*) : Command?
    full_args = args.value.select { |_, v| v.kind.argument? && !v.string? }
    return command if full_args.empty? || command.children.empty?

    key, res = full_args.first
    if cmd = command.children.values.find &.is?(res.value)
      args.value.delete key
      resolve_command cmd, args
    elsif !command.arguments.empty?
      command
    else
      nil
    end
  end

  private def self.get_in_position(command : Command, results : Hash(Int32, Parser::Result)) : Result
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

            raise ExecutionError.new "Missing argument for option '#{opt}'" unless opt.has_default?
            opt.value = Value.new opt.default
            parsed_opts[opt.long] = opt
          end
        else
          raise ExecutionError.new "Option '#{opt}' takes no arguments" if res.value.includes? '='
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

    Result.new(parsed_opts, unknown_opts, missing_opts, parsed_args, unknown_args, missing_args)
  end

  private def self.finalize(command : Command, res : Result) : Nil
    command.on_unknown_options(res.unknown_opts) unless res.unknown_opts.empty?
    command.on_missing_options(res.missing_opts) unless res.missing_opts.empty?
    command.on_missing_arguments(res.missing_args) unless res.missing_args.empty?
    command.on_unknown_arguments(res.unknown_args) unless res.unknown_args.empty?
  end
end
