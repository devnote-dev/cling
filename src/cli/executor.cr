# Handles the execution of commands. In most cases you should never need to interact with this
# module as the `Command#execute` method is the main entrypoint for executing commands. For this
# reason, most of the modules methods are hidden.
module CLI::Executor
  private struct Result
    getter parsed_options : OptionsInput
    getter unknown_options : Array(String)
    getter missing_options : Array(String)
    getter parsed_arguments : ArgumentsInput
    getter unknown_arguments : Array(String)
    getter missing_arguments : Array(String)

    def initialize(parsed_options, @unknown_options, @missing_options, parsed_arguments, @unknown_arguments, @missing_arguments)
      @parsed_options = OptionsInput.new parsed_options
      @parsed_arguments = ArgumentsInput.new parsed_arguments
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
  def self.handle(command : Command, results : Array(Parser::Result)) : Nil
    resolved_command = resolve_command command, results
    unless resolved_command
      command.on_error CommandError.new("Command '#{results.first.value}' not found")
      return
    end

    executed = get_in_position resolved_command, results
    puts results

    begin
      res = resolved_command.pre_run executed.parsed_arguments, executed.parsed_options
      unless res.nil?
        return unless res
      end
    rescue ex
      resolved_command.on_error ex
    end

    finalize resolved_command, executed

    begin
      resolved_command.run executed.parsed_arguments, executed.parsed_options
      resolved_command.post_run executed.parsed_arguments, executed.parsed_options
    rescue ex
      resolved_command.on_error ex
    end
  end

  private def self.resolve_command(command : Command, results : Array(Parser::Result)) : Command?
    arguments = results.select { |r| r.kind.argument? && !r.string? }
    return command if arguments.empty? || command.children.empty?

    result = arguments.first
    if found_command = command.children.values.find &.is?(result.value)
      results.shift
      resolve_command found_command, results
    elsif !command.arguments.empty?
      command
    else
      nil
    end
  end

  private def self.get_in_position(command : Command, results : Array(Parser::Result)) : Result
    options = results.reject &.kind.argument?
    parsed_options = {} of String => Option
    unknown_options = [] of String

    options.each_with_index do |result, index|
      if option = command.options.values.find &.is?(result.parse_key)
        if option.type.none?
          raise ExecutionError.new("Option '#{option}' takes no arguments") if result.value.includes? '='
        else
          if result.value.includes?('=')
            option.value = if option.type.single?
                             Value.new result.parse_value
                           else
                             Value.new result.parse_value.split(',')
                           end
          else
            if argument = results[index + 1]?
              if argument.kind.argument?
                option.value = if option.type.single?
                                 Value.new argument.value
                               else
                                 Value.new argument.value.split(',')
                               end

                parsed_options[option.long] = option
                results.delete_at(index + 1)
                next
              end
            end

            raise ExecutionError.new("Missing argument for option '#{option}'") unless option.has_default?
            option.value = Value.new option.default
          end
        end
        parsed_options[option.long] = option
      else
        unknown_options << result.parse_key
      end
    end

    default_options = command.options
      .select { |_, v| v.has_default? }
      .reject { |k, _| parsed_options.has_key?(k) }

    parsed_options.merge! default_options
    missing_options = command.options
      .select { |_, v| v.required? }
      .keys
      .reject { |k| parsed_options.has_key?(k) }

    arguments = results.select &.kind.argument?
    parsed_arguments = {} of String => Argument
    missing_arguments = [] of String

    command.arguments.values.each_with_index do |argument, index|
      if res = arguments[index]?
        argument.value = Value.new res.value
        parsed_arguments[argument.name] = argument
        results.delete_at index
      else
        missing_arguments << argument.name if argument.required?
      end
    end

    unknown_arguments = if arguments.empty?
                          [] of String
                        else
                          arguments[parsed_arguments.size...].map &.value
                        end

    Result.new(
      parsed_options,
      unknown_options,
      missing_options,
      parsed_arguments,
      unknown_arguments,
      missing_arguments
    )
  end

  private def self.finalize(command : Command, res : Result) : Nil
    command.on_unknown_options(res.unknown_options) unless res.unknown_options.empty?
    command.on_missing_options(res.missing_options) unless res.missing_options.empty?
    command.on_missing_arguments(res.missing_arguments) unless res.missing_arguments.empty?
    command.on_unknown_arguments(res.unknown_arguments) unless res.unknown_arguments.empty?
  end
end
