# Handles the execution of commands. In most cases you should never need to interact with this
# module as the `Command#execute` method is the main entrypoint for executing commands. For this
# reason, most of the modules methods are hidden.
module Cling::Executor
  private struct Result
    getter parsed_options : Options
    getter unknown_options : Array(String)
    getter missing_options : Array(String)
    getter parsed_arguments : Arguments
    getter unknown_arguments : Array(String)
    getter missing_arguments : Array(String)

    def initialize(parsed_options, @unknown_options, @missing_options, parsed_arguments,
                   @unknown_arguments, @missing_arguments)
      @parsed_options = Options.new parsed_options
      @parsed_arguments = Arguments.new parsed_arguments
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

    begin
      executed = get_in_position resolved_command, results
    rescue ex : ExecutionError
      resolved_command.on_invalid_option ex.to_s
      return
    end

    begin
      res = resolved_command.pre_run executed.parsed_arguments, executed.parsed_options
      return unless res.nil? || res
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
    options = {} of String => Value
    parsed_options = {} of String => Option
    unknown_options = [] of String

    results.each_with_index do |result, index|
      next if result.kind.argument?

      if option = command.options.values.find &.is?(result.key)
        if option.type.none?
          raise ExecutionError.new "Option '#{option}' takes no arguments" if result.value?
          options[option.long] = Value.new nil
        else
          if result.value?
            if current = options[option.long]?
              options[option.long] = Value.new(current.as_a << result.value)
            elsif option.type.multiple?
              options[option.long] = Value.new [result.value]
            else
              options[option.long] = Value.new result.value
            end
          elsif res = results[index + 1]?
            unless res.kind.argument?
              raise ExecutionError.new "Missing required argument#{"s" if option.type.multiple?} for option '#{option}'"
            end

            if option.type.single?
              options[option.long] = Value.new res.value
            else
              if current = options[option.long]?
                options[option.long] = Value.new(current.as_a << res.value)
              else
                options[option.long] = Value.new [res.value]
              end
            end

            results.delete_at(index + 1)
          elsif default = option.default
            unless option.required?
              raise ExecutionError.new "Missing required argument#{"s" if option.type.multiple?} for option '#{option}'"
            end

            if option.type.single?
              options[option.long] = Value.new default
            else
              if current = options[option.long]?
                options[option.long] = Value.new(current.as_a << default.to_s)
              else
                options[option.long] = Value.new [default.to_s]
              end
            end

            results.delete_at index if 0 <= index > results.size
          else
            raise ExecutionError.new "Missing required argument#{"s" if option.type.multiple?} for option '#{option}'"
          end
        end
      else
        unknown_options << result.key
      end
    end

    options.each do |key, value|
      option = command.options[key]
      if option.type.none?
        raise ExecutionError.new("Option '#{option}' takes no arguments") unless value.raw.nil?
      else
        if value.raw.nil?
          raise ExecutionError.new "Missing required argument#{"s" if option.type.multiple?} for option '#{option}'"
        end

        if option.type.multiple? && !value.raw.is_a?(Array)
          str = value.raw.to_s
          value = if str.includes?(',')
                    Value.new str.split(',', remove_empty: true)
                  else
                    Value.new [str]
                  end
        end
      end

      option.value = value
      parsed_options[option.long] = option
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
      else
        missing_arguments << argument.name if argument.required?
      end
    end

    unknown_arguments = if arguments.empty?
                          [] of String
                        else
                          arguments[parsed_arguments.size...].map &.value
                        end

    if argument = parsed_arguments.values.find &.multiple?
      argument.value = Value.new([argument.value.as(Value).as_s] + unknown_arguments)
      unknown_arguments.clear
      parsed_arguments[argument.name] = argument
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
