module CLI
  struct Option
    property long : String
    property short : String?
    property description : String?
    property? required : Bool
    property kind : ValueKind
    property value : String?
    property? has_default : Bool

    def_equals @long, @short

    def initialize(@long, @short = nil, @description = nil, @required = false, @kind = :none,
                   default : String? = nil)
      @value = default
      @has_default = default ? true : false
    end

    def to_s : String
      @short || @long
    end

    def to_s(io : IO) : Nil
      io << to_s
    end
  end

  class OptionsInput
    property options : Array(Option)

    def initialize(@options)
    end

    def [](name : String) : Option
      @options.find! { |o| o.short == name || o.long == name }
    end

    def []?(name : String) : Option?
      @options.find { |o| o.short == name || o.long == name }
    end

    def has?(name : String) : Bool
      !self[name]?.nil?
    end

    def get(name : String) : String?
      self[name]?.try &.value
    end

    def get!(name : String) : String
      get(name).not_nil!
    end
  end
end
