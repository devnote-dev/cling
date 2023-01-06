require "cli"
require "./welcome_command"

class MainCommand < CLI::Command
  def setup : Nil
    @name = "greet"
    @description = "Greets a person"
    add_argument "name", description: "the name of the person to greet", required: true
    add_option 'c', "caps", description: "greet with capitals"
    add_option 'h', "help", description: "sends help information"
  end

  def pre_run(arguments : ArgumentsInput, options : OptionsInput) : Bool
    if options.has? "help"
      puts help_template # generated using CLI::Formatter

      false
    else
      true
    end
  end

  def run(arguments : CLI::ArgumentsInput, options : CLI::OptionsInput) : Nil
    msg = "Hello, #{arguments.get("name")}!"

    if options.has? "caps"
      puts msg.upcase
    else
      puts msg
    end
  end
end

main = MainCommand.new
main.add_command WelcomeCommand.new

main.execute ARGV
