require "cli"
require "./welcome_cmd"

class MainCmd < CLI::Command
  def setup : Nil
    @name = "greet"
    @description = "Greets a person"
    add_argument "name", desc: "the name of the person to greet", required: true
    add_option 'c', "caps", desc: "greet with capitals"
    add_option 'h', "help", desc: "sends help information"
  end

  def pre_run(args, options)
    if options.has? "help"
      puts help_template # generated using CLI::Formatter

      false
    else
      true
    end
  end

  def run(args, options) : Nil
    msg = "Hello, #{args.get("name")}!"

    if options.has? "caps"
      puts msg.upcase
    else
      puts msg
    end
  end
end

main = MainCmd.new
main.add_command WelcomeCmd.new

main.execute ARGV
