require "cling"
require "./welcome_command"

class MainCommand < Cling::Command
  def setup : Nil
    @name = "greet"
    @description = "Greets a person"
    add_argument "name", description: "the name of the person to greet", required: true
    add_option 'c', "caps", description: "greet with capitals"
    add_option 'h', "help", description: "sends help information"
  end

  def pre_run(arguments : Cling::ArgumentsInput, options : Cling::OptionsInput) : Bool
    if options.has? "help"
      puts help_template # generated using Cling::Formatter

      false
    else
      true
    end
  end

  def run(arguments : Cling::ArgumentsInput, options : Cling::OptionsInput) : Nil
    message = "Hello, #{arguments.get("name")}!"

    if options.has? "caps"
      puts message.upcase
    else
      puts message
    end
  end
end

main = MainCommand.new
main.add_command WelcomeCommand.new

main.execute ARGV
