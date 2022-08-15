module CLI
  struct Argument
    property name : String
    property description : String?
    property value : String
    property default : Any = nil

    def initialize(@name, @description, @value, @default)
    end

    def to_s(io : IO) : Nil
      io << @name
    end

    def inspect(io : IO) : Nil
      io << "#<Argument:" << @name << ">"
    end

    def parse(type : T.class) : T forall T
      {% if T.is_a? Nil %}
        nil
      {% elsif T.is_a? String %}
        @value
      {% elsif T.is_a? Bool %}
        case @value
        when "true" then true
        when "false" then false
        else
          raise "Invalid argument value for Bool"
        end
      {% elsif T.in? %w(Int8 Int16 Int32 Int64) %}
        @value.to_i{{ T.id.stringify[3..] }}
      {% elsif T.in? %w(Float32 Float64) %}
        @value.to_f{{ T.id.stringify[5..] }}
      {% else %}
        {% if T.responds_to?(:arg_parse) %}
          {{ T.id }}.arg_parse @value
        {% else %}
          raise "Cannot parse argument to type {{ T.id.stringify }}"
        {% end %}
      {% end %}
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

    def get(name : String) : String
      @arguments[name].value
    end

    def get(name : String, type : T.class) : T forall T
      @arguments[name].parse type
    end
  end
end
