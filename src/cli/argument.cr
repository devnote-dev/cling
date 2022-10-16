module CLI
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

    def to_s(io : IO) : Nil
      io << @name
    end
  end

  struct ArgsInput
    getter args : Hash(String, Argument)

    def initialize(@args)
    end

    def [](key : String) : Argument
      @args[key]
    end

    def []?(key : String) : Argument?
      @args[key]?
    end

    def has?(key : String) : Bool
      @args.has_key? key
    end

    def get(key : String | Char) : Value?
      self[key]?.try &.value
    end

    def get!(key : String | Char) : Value
      self[key].value.not_nil!
    end

    def empty? : Bool
      @args.empty?
    end

    def size : Int32
      @args.size
    end
  end
end
