module CLI
  struct Value
    alias Type = String | Number::Primitive | Bool | Nil # | Array(Type)

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
      "f" => Float,
      "bool" => Bool,
      "a" => Array(Type),
      "h" => Hash(Type, Type)
    } %}
    def as_{{ name.id }} : {{ type }}
      @raw.as({{ type }})
    end

    def as_{{ name.id }}? : {{ type }}?
      @raw.as?({{ type }})
    end
    {% end %}

    {% for base in %w(8 16 32 64 128) %}
    def as_i{{ base.id }} : Int{{ base.id }}
      @raw.as(Int{{ base.id }}).to_i{{ base.id }}
    end

    def as_i{{ base.id }}? : Int{{ base.id }}?
      @raw.as?(Int{{ base.id }}).try &.to_i{{ base.id }}?
    end

    def as_u{{ base.id }} : Int{{ base.id }}
      @raw.as(UInt{{ base.id }}).to_u{{ base.id }}
    end

    def as_u{{ base.id }}? : Int{{ base.id }}?
      @raw.as?(UInt{{ base.id }}).try &.to_u{{ base.id }}?
    end
    {% end %}

    {% for base in %w(32 64) %}
    def as_f{{ base.id }} : Float{{ base.id }}
      @raw.as(Float{{ base.id }}).to_f{{ base.id }}
    end

    def as_f{{ base.id }}? : Float{{ base.id }}?
      @raw.as?(Float{{ base.id }}).try &.to_f{{ base.id }}?
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
