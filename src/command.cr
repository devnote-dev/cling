module CLI
  abstract class Command
    property name : String
    property usage : Array(String)
    property description : String?
    property short_help : String?
    property arguments : Hash(String, Argument)
    property options : Hash(String, Option)

    def initialize(@name)
      @usage = [] of String
      @arguments = {} of String => Argument
      @options = {} of String => Option

      setup
    end

    abstract def setup : Nil

    abstract def execute(args, options) : Nil
  end
end
