module CLI
  struct Option
    property long : String
    property short : String?
    property description : String?
    property? required : Bool
    property kind : ValueKind
    property value : String?
    property default : Any = nil

    def initialize(@long, @short = nil, @description = nil, @required = false,
                   @kind = :none, @default = nil)
      @value = nil
    end

    def to_s(io : IO) : Nil
      @long
    end

    def inspect(io : IO) : Nil
      io << "#<Option @long:"
      @long.inspect io
      io << " @short:"
      @short.inspect io
      io << ">"
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
      !@options.has_key?
    end

    def get(name : String) : String?
      self[name].value
    end

    def get(name : String, type : T.class) : T forall T
      self[name].parse type
    end
  end
end
