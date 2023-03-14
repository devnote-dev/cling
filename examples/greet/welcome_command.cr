class WelcomeCommand < Cling::Command
  def setup : Nil
    @name = "welcome"
    @summary = @description = "sends a friendly welcome message"

    add_argument "name", description: "the name of the person to greet", required: true
    # this will inherit the header and footer properties
    @inherit_borders = true
    # this will NOT inherit the parent flag options
    @inherit_options = false
    # this will inherit the input, output and error IO streams
    @inherit_streams = true
  end

  def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Bool
    if options.has? "help"
      puts help_template # generated using Cling::Formatter

      false
    else
      true
    end
  end

  def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
    stdout.puts "Welcome to the CLI world, #{arguments.get("name")}!"
  end
end
