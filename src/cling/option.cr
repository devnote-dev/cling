module Cling
  # Represents a command line flag option, supporting boolean and string values. Options are parsed
  # after the main command taking priority over the argument resolution (see `Executor#handle`).
  class Option
    # Identifies the value type of the option. `None` (the default) will not accept any arguments,
    # `Single` will accept exactly 1 argument, and `Multiple` will accept multiple arguments.
    # Multiple type options also support specifying the option name more than once in the command
    # line:
    #
    # ```
    # command argument --option=1,2,3 # allowed
    # command argument -o 1 -o=2 -o 3 # also allowed
    # ```
    enum Type
      None
      Single
      Multiple
    end

    property long : String
    property short : Char?
    property description : String?
    property? required : Bool
    property? hidden : Bool
    property type : Type
    property default : Value::Type
    property value : Value?

    def_equals @long, @short

    def initialize(@long : String, @short : Char? = nil, @description : String? = nil,
                   @required : Bool = false, @hidden : Bool = false, @type : Type = :none,
                   @default : Value::Type = nil)
      if type.none? && default
        raise ArgumentError.new "A default value for a flag option that takes no arguments is useless"
      end
      raise ArgumentError.new "Required options cannot have a default value" if required && default

      @value = Value.new @default
    end

    # :inherit:
    def to_s(io : IO) : Nil
      io << @long
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
  struct Options
    getter hash : Hash(String, Option)

    # :nodoc:
    def initialize(@hash)
    end

    # Indexes an option by its long name and returns the `Option` object, not the option's
    # value.
    def [](key : String) : Option
      @hash[key] rescue raise ValueNotFound.new(key)
    end

    # Indexes an option by its short name and returns the `Option` object, not the option's
    # value.
    def [](key : Char) : Option
      @hash.values.find! &.short.== key
    rescue
      raise ValueNotFound.new(key.to_s)
    end

    # Indexes an option by its long name and returns the `Option` object or `nil` if not found,
    # not the option's value.
    def []?(key : String) : Option?
      @hash[key]?
    end

    # Indexes an option by its short name and returns the `Option` object or `nil` if not found,
    # not the option's value.
    def []?(key : Char) : Option?
      @hash.values.find &.is? key.to_s
    end

    # Returns `true` if an option by the given long name exists.
    def has?(key : String) : Bool
      @hash.has_key?(key) || !@hash.values.find(&.is? key).nil?
    end

    # Returns `true` if an option by the given short name exists.
    def has?(key : Char) : Bool
      has? key.to_s
    end

    # Gets an option by its short or long name and returns its `Value`, or `nil` if not found.
    def get?(key : String | Char) : Value?
      self[key]?.try &.value
    end

    # Gets an option by its short or long name and returns its `Value`.
    def get(key : String | Char) : Value
      self[key].value || raise ValueNotFound.new(key.to_s)
    end

    # Returns `true` if there are no parsed options.
    def empty? : Bool
      @hash.empty?
    end

    # Returns the number of parsed options.
    def size : Int32
      @hash.size
    end
  end
end
