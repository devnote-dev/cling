module Cling
  # Represents a command line flag option, supporting boolean and string values. Options are parsed
  # after the main command taking priority over the argument resolution (see `Executor#handle`).
  class Option
    # Identifies the value type of the option. `None` (the default) will not accept any arguments,
    # `Single` will accept exactly 1 argument, and `Array` will accept multiple arguments. Array
    # type options also support specifying the option name more than once in the command line:
    #
    # ```
    # command argument --option=1,2,3 # allowed
    # command argument -o 1 -o=2 -o 3 # also allowed
    # ```
    enum Type
      None
      Single
      Array
    end

    property long : String
    property short : Char?
    property description : String?
    property? required : Bool
    property type : Type
    property default : Value::Type
    property value : Value?

    def_equals @long, @short

    def initialize(@long : String, @short : Char? = nil, @description : String? = nil,
                   @required : Bool = false, @type : Type = :none, @default : Value::Type = nil)
      @value = Value.new(@default)
    end

    # :inherit:
    def to_s(io : IO) : Nil
      io << @short || @long
    end

    # Returns `true` if a default value is set.
    def has_default? : Bool
      !@default.nil?
    end

    # Returns true if the name matches the option's long or short flag name.
    def is?(name : String) : Bool
      @short.to_s == name || @long == name
    end
  end

  # An input structure to access validated options at execution time.
  struct OptionsInput
    getter options : Hash(String, Option)

    # :nodoc:
    def initialize(@options)
    end

    # Indexes an option by its long name and returns the `Option` object, not the option's
    # value.
    def [](key : String) : Option
      @options[key]
    end

    # Indexes an option by its short name and returns the `Option` object, not the option's
    # value.
    def [](key : Char) : Option
      @options.values.find! &.short.==(key)
    end

    # Indexes an option by its long name and returns the `Option` object or `nil` if not found,
    # not the option's value.
    def []?(key : String) : Option?
      @options[key]?
    end

    # Indexes an option by its short name and returns the `Option` object or `nil` if not found,
    # not the option's value.
    def []?(key : Char) : Option?
      @options.values.find &.short.==(key)
    end

    # Returns `true` if an option by the given long name exists.
    def has?(key : String) : Bool
      @options.has_key? key
    end

    # Returns `true` if an option by the given short name exists.
    def has?(key : Char) : Bool
      !self[key]?.nil?
    end

    # Gets an option by its short or long name and returns its `Value`, or `nil` if not found.
    def get(key : String | Char) : Value?
      self[key]?.try &.value
    end

    # Gets an option by its short or long name and returns its `Value`.
    def get!(key : String | Char) : Value
      self[key].value.not_nil!
    end

    # Returns `true` if there are no parsed options.
    def empty? : Bool
      @options.empty?
    end

    # Returns the number of parsed options.
    def size : Int32
      @options.size
    end
  end
end
