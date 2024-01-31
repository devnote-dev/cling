module Cling
  abstract class MainCommand < Command
    def setup : Nil
      @name = "main"
      @version = "version 0.0.1"
      @inherit_borders = true
      @inherit_options = true

      add_option 'h', "help", description: "sends help information"
      add_option 'v', "version", description: "sends the app version"
    end

    def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      if arguments.empty? && options.empty?
        Formatter.new.generate(self).to_s(stdout)
        exit_program 0
      end

      case options
      when .has? "help"
        Formatter.new.generate(self).to_s(stdout)

        exit_program 0
      when .has? "version"
        puts @version

        exit_program 0
      end
    end
  end
end
