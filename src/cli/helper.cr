module CLI
  abstract class MainCommand < Command
    def setup : Nil
      @name = "main"
      @version = "version 0.0.1"
      @inherit_borders = true
      @inherit_options = true

      add_option 'h', "help", desc: "sends help information"
      add_option 'v', "version", desc: "sends the app version"
    end

    def pre_run(args, options)
      if args.empty? && options.empty?
        Formatter.new(self).generate.to_s(stdout)
        return false
      end

      case options
      when .has? "help"
        Formatter.new(self).generate.to_s(stdout)

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
