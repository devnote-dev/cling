class WelcomeCmd < CLI::Command
  def setup : Nil
    @name = "welcome"
    @summary = @description = "sends a friendly welcome message"

    add_argument "name", desc: "the name of the person to greet", required: true
    # this will inherit the header and footer properties
    inherit_borders = true
    # this will NOT inherit the parent flag options
    inherit_options = false
    # this will inherit the input, output and error IO streams
    inherit_streams = true
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
    stdout.puts "Welcome to the CLI world, #{args.get("name")}!"
  end
end
