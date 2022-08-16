module CLI
  struct Argument
    property name : String
    property description : String?
    property? required : Bool
    property kind : ValueKind
    property value : String?

    def initialize(@name, @description = nil, @required = false, @kind = :none)
      @value = nil
    end

    def to_s(io : IO) : Nil
      io << @name
    end
  end

  class ArgsInput
    property arguments : Hash(String, Argument)

    def initialize(@arguments)
    end

    def [](name : String) : Argument
      @arguments[name]
    end

    def []?(name : String) : Argument?
      @arguments[name]?
    end

    def has?(name : String) : Bool
      !@arguments[name]?.nil?
    end

    def get(name : String) : String?
      self[name]?.try &.value
    end
  end
end
