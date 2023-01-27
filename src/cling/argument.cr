module Cling
  # Represents a command line argument, this can be a single value or a string value. Arguments are
  # parsed after the main command and any subcommands are resolved. Note that `Option`s that have
  # values take priority in the resolution list, so the following example would only yield 2
  # arguments:
  #
  # ```
  # ./greet --time=day Dev
  # #              ^^^
  # # belongs to the flag option
  # ```
  #
  # Arguments should typically be defined in the `Command#setup` method of a command using
  # `Command#add_argument` to prevent conflicts.
  class Argument
    property name : String
    property description : String?
    property? required : Bool
    property? has_value : Bool
    property value : Value?

    def initialize(@name : String, @description : String? = nil, @required : Bool = false)
      @has_value = false
      @value = nil
    end

    # :inherit:
    def to_s(io : IO) : Nil
      io << @name
    end
  end

  # An input structure to access validated arguments at execution time.
  struct ArgumentsInput
    getter arguments : Hash(String, Argument)

    # :nodoc:
    def initialize(@arguments)
    end

    # Indexes an argument by its name and returns the `Argument` object, not the argument's
    # value.
    def [](key : String) : Argument
      @arguments[key]
    end

    # Indexes an argument by its name and returns the `Argument` object or `nil` if not found,
    # not the argument's value.
    def []?(key : String) : Argument?
      @arguments[key]?
    end

    # Returns `true` if an argument by the given name exists.
    def has?(key : String) : Bool
      @arguments.has_key? key
    end

    # Gets an argument by its name and returns its `Value`, or `nil` if not found.
    def get(key : String) : Value?
      self[key]?.try &.value
    end

    # Gets an argument by its name and returns its `Value`.
    def get!(key : String) : Value
      self[key].value.not_nil!
    end

    # Returns `true` if there are no parsed arguments.
    def empty? : Bool
      @arguments.empty?
    end

    # Returns the number of parsed arguments.
    def size : Int32
      @arguments.size
    end
  end
end
