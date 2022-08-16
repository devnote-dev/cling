module CLI
  struct Option
    property long : String
    property short : String?
    property description : String?
    property? required : Bool
    property kind : ValueKind
    property value : String?

    def initialize(@long, @short = nil, @description = nil, @required = false, @kind = :none)
      @value = nil
    end

    def to_s(io : IO) : Nil
      @long
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
  end
end
