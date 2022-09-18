module CLI
  class Argument
    property name : String
    property description : String?
    property? required : Bool
    property? has_value : Bool
    property value : String?

    def initialize(@name : String, @description : String? = nil, @required : Bool = false)
      @has_value = false
      @value = nil
    end

    def to_s(io : IO) : Nil
      io << @name
    end
  end
end
