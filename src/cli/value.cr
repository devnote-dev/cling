module CLI
  struct Value
    alias Type = String | Int64 | Float64 | Bool | Nil | Array(Type) | Hash(Type, Type)

    getter raw : Type

    def initialize(@raw : Type)
    end

    def to_s(io : IO) : Nil
      @raw.to_s io
    end

    def size : Int32
      case value = @raw
      when Array
        value.size
      when Hash
        value.size
      else
        raise "Cannot get size of type #{value.class}"
      end
    end

    def ==(other : Type) : Bool
      @raw == other
    end

    {% for name, type in {
      "s" => String,
      "i" => Int,
      "i64" => Int,
      "f" => Float,
      "f64" => Float,
      "bool" => Bool,
      "a" => Array(Type),
      "h" => Hash(Type, Type)
    } %}
    def as_{{ name.id }} : {{ type }}
      @raw.as({{ type }}){% if {"i", "i64", "f", "f64"}.includes?(name) %}.to_{{ name.id }}{% end %}
    end

    def as_{{ name.id }}? : {{ type }}?
      @raw.as?({{ type }}){% if {"i", "i64", "f", "f64"}.includes?(name) %}.to_{{ name.id }}?{% end %}
    end
    {% end %}

    def as_nil : Nil
      @raw.as(Nil)
    end

    def [](index : Int32) : Type
      case value = @raw
      when Array
        value[index]
      else
        raise "Cannot get index of type #{value.class}"
      end
    end

    def []?(index : Int32) : Type
      case value = @raw
      when Array
        value[index]?
      else
        raise "Cannot get index of type #{value.class}"
      end
    end

    def [](index : Range) : Type
      case value = @raw
      when Array
        value[index]
      else
        raise "Cannot get index of type #{value.class}"
      end
    end

    def []?(index : Range) : Type
      case value = @raw
      when Array
        value[index]?
      else
        raise "Cannot get index of type #{value.class}"
      end
    end

    def [](key : String) : Type
      case value = @raw
      when Hash
        value[index]
      else
        raise "Cannot get index of type #{value.class}"
      end
    end

    def []?(key : String) : Type
      case value = @raw
      when Hash
        value[index]
      else
        raise "Cannot get index of type #{value.class}"
      end
    end
  end
end
