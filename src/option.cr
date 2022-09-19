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

    class Value
      alias Type = String | Int64 | Float64 | Bool | Nil | Array(Type) | Hash(Type, Type)

      getter raw : Type

      def initialize(@raw)
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
end
