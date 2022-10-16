module CLI
  class Option
    property long : String
    property short : Char?
    property description : String?
    property? required : Bool
    getter? has_value : Bool
    property default : Value::Type
    property value : Value?

    def_equals @long, @short

    def initialize(@long : String, @short : Char? = nil, @description : String? = nil,
                   @required : Bool = false, @has_value : Bool = false, @default : Value::Type = nil)
      @value = nil
    end

    def to_s(io : IO) : Nil
      io << @short || @long
    end

    def has_default? : Bool
      !@default.nil?
    end

    def is?(name : String) : Bool
      @short.to_s == name || @long == name
    end
  end

  struct OptionsInput
    getter options : Hash(String, Option)

    def initialize(@options)
    end

    def [](key : String) : Option
      @options[key]
    end

    def [](key : Char) : Option
      @options.values.find! &.short.==(key)
    end

    def []?(key : String) : Option?
      @options[key]?
    end

    def []?(key : Char) : Option?
      @options.values.find &.short.==(key)
    end

    def has?(key : String) : Bool
      @options.has_key? key
    end

    def has?(key : Char) : Bool
      !self[key]?.nil?
    end

    def get(key : String | Char) : Value?
      self[key]?.try &.value
    end

    def get!(key : String | Char) : Value
      self[key].value.not_nil!
    end

    def empty? : Bool
      @options.empty?
    end

    def size : Int32
      @options.size
    end
  end
end
