module Cling
  # Represents a value for an argument or option.
  struct Value
    alias Type = String | Number::Primitive | Bool | Nil | Array(String)

    getter raw : Type

    delegate :==, :===, :to_s, to: @raw

    def initialize(@raw : Type)
    end

    # Returns the size of the value if it is an array or hash, otherwise raises an exception.
    def size : Int32
      case value = @raw
      when Array
        value.size
      when Hash
        value.size
      else
        raise ArgumentError.new "Cannot get size of type #{value.class}"
      end
    end

    # Returns the value as a `String`.
    def as_s : String
      @raw.as(String)
    end

    # Returns the value as a `String` or `nil` if the underlying value is not a string.
    def as_s? : String?
      @raw.as?(String)
    end

    # Returns the value as an `Int`.
    def as_i : Int
      @raw.as(Int)
    end

    # Returns the value as a `Int` or `nil` if the underlying value is not an integer.
    def as_i? : Int?
      @raw.as?(Int)
    end

    # Conversts the value to an `Int`.
    def to_i : Int
      @raw.to_s.to_i
    end

    # Converts the value to an `Int` or `Nil` if the underlying value cannot be parsed.
    def to_i? : Int?
      @raw.to_s.to_i?
    end

    # Returns the value as a `Float`.
    def as_f : Float
      @raw.as(Float)
    end

    # Returns the value as a `Float` or `nil` if the underlying value is not a float.
    def as_f? : Float?
      @raw.as?(Float)
    end

    # Converts the value to a `Float`.
    def to_f : Float
      @raw.to_s.to_f
    end

    # Converts the value to a `Float` or `Nil` if the underlying value cannot be parsed.
    def to_f? : Float?
      @raw.to_s.to_f?
    end

    # Returns the value as a `Bool`.
    def as_bool : Bool
      @raw.as(Bool)
    end

    # Returns the value as a `Bool` or `nil` if the underlying value is not a boolean.
    def as_bool? : Bool?
      @raw.as?(Bool)
    end

    # Converts the value to a `Bool`.
    def to_bool : Bool
      value = to_bool?
      return value unless value.nil?

      raise ArgumentError.new "cannot parse Bool from #{@raw.class}"
    end

    # Converts the value to a `Bool` or `Nil` if the underlying value cannot be parsed.
    def to_bool? : Bool?
      case @raw.to_s
      when "true"  then true
      when "false" then false
      else              nil
      end
    end

    # Returns the value as an `Array`. Note that this does not change the type of the array.
    def as_a : Array(String)
      @raw.as(Array(String))
    end

    # Returns the value as an `Array`. Note that this does not change the type of the array.
    # Returns `nil` if the underlying value is not an array.
    def as_a? : Array(String)?
      @raw.as?(Array(String))
    end

    {% for base in %w(8 16 32 64 128) %}
    # Returns the value as an `Int{{ base }}`.
    def as_i{{ base.id }} : Int{{ base.id }}
      @raw.as(Int{{ base.id }})
    end

    # Returns the value as an `Int{{ base }}` or `nil`.
    def as_i{{ base.id }}? : Int{{ base.id }}?
      @raw.as?(Int{{ base.id }})
    end

    # Converts the value to an `Int{{ base.id }}`.
    def to_i{{ base.id }} : Int{{ base.id }}
      @raw.to_s.to_i{{ base.id }}
    end

    # Converts the value to an `Int{{ base.id }}` or `Nil` if the underlying value cannot be parsed.
    def to_i{{ base.id }}? : Int{{ base.id }}?
      @raw.to_s.to_i{{ base.id }}?
    end

    # Returns the value as a `UInt{{ base }}`.
    def as_u{{ base.id }} : UInt{{ base.id }}
      @raw.as(UInt{{ base.id }})
    end

    # Returns the value as a `UInt{{ base }}` or `nil`.
    def as_u{{ base.id }}? : UInt{{ base.id }}?
      @raw.as?(UInt{{ base.id }})
    end

    # Converts the value to a `UInt{{ base.id }}`.
    def to_u{{ base.id }} : UInt{{ base.id }}
      @raw.to_s.to_u{{ base.id }}
    end

    # Converts the value to a `UInt{{ base.id }}` or `Nil` if the underlying value cannot be parsed.
    def to_u{{ base.id }}? : UInt{{ base.id }}?
      @raw.to_s.to_u{{ base.id }}?
    end
    {% end %}

    {% for base in %w(32 64) %}
    # Returns the value as a `Float{{ base }}`.
    def as_f{{ base.id }} : Float{{ base.id }}
      @raw.as(Float{{ base.id }})
    end

    # Returns the value as a `Float{{ base }}` or `nil`.
    def as_f{{ base.id }}? : Float{{ base.id }}?
      @raw.as?(Float{{ base.id }})
    end

    # Converts the value to a `Float{{ base.id }}`.
    def to_f{{ base.id }} : Float{{ base.id }}
      @raw.to_s.to_f{{ base.id }}
    end

    # Converts the value to a `Float{{ base.id }}` or `Nil` if the underlying value cannot be parsed.
    def to_f{{ base.id }}? : Float{{ base.id }}?
      @raw.to_s.to_f{{ base.id }}?
    end
    {% end %}

    # Indexes the value if the value is an array, otherwise raises an exception.
    def [](index : Int32) : Type
      case value = @raw
      when Array
        value[index]
      else
        raise "Cannot get index of type #{value.class}"
      end
    end

    # Attempts to index the value if the value is an array or returns `nil`, otherwise raises an
    # exception.
    def []?(index : Int32) : Type
      case value = @raw
      when Array
        value[index]?
      else
        raise ArgumentError.new "Cannot get index of type #{value.class}"
      end
    end

    # :ditto:
    def [](index : Range) : Type
      case value = @raw
      when Array
        value[index]
      else
        raise ArgumentError.new "Cannot get index of type #{value.class}"
      end
    end

    # :ditto:
    def []?(index : Range) : Type
      case value = @raw
      when Array
        value[index]?
      else
        raise ArgumentError.new "Cannot get index of type #{value.class}"
      end
    end

    # Indexes the value if the value is a hash, otherwise raises an exception.
    def [](key : String) : Type
      case value = @raw
      when Hash
        value[index]
      else
        raise ArgumentError.new "Cannot get index of type #{value.class}"
      end
    end

    # Attempts to index the value if the value is a hash or returns `nil`, otherwise raises an
    # exception.
    def []?(key : String) : Type?
      case value = @raw
      when Hash
        value[index]?
      else
        raise ArgumentError.new "Cannot get index of type #{value.class}"
      end
    end
  end
end
