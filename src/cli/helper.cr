module CLI
  abstract class MainCommand < Command
    def setup : Nil
      @name = "main"
      @version = "version 0.0.1"
      @inherit_borders = true
      @inherit_options = true

      add_option 'h', "help", description: "sends help information"
      add_option 'v', "version", description: "sends the app version"
    end

    def pre_run(arguments : CLI::ArgumentsInput, options : CLI::OptionsInput) : Bool
      if arguments.empty? && options.empty?
        Formatter.new.generate(self).to_s(stdout)
        return false
      end

      case options
      when .has? "help"
        Formatter.new.generate(self).to_s(stdout)

        false
      when .has? "version"
        puts @version

        false
      else
        true
      end
    end
  end
end
