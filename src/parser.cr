module CLI
  alias MappedArgs = Array({kind: Symbol, name: String, value: String?})

  class Parser
    @reader : Char::Reader
    @parsed : MappedArgs

    def initialize(@short_long : Bool, @long_short : Bool, @parse_string : Bool,
                   @string_delimiters : Array(Char), @option_delimiter : Char)
      @reader = uninitialized Char::Reader
      @parsed = MappedArgs.new
    end

    def parse(input : Array(String)) : MappedArgs
      parse input.join(' ')
    end

    def parse(input : String) : MappedArgs
      @reader = Char::Reader.new input

      loop do
        case char = @reader.current_char
        when '\0'
          break
        when ' '
          @reader.next_char
          next
        when '-'
          if @option_delimiter == '-'
            read_option
          else
            read_argument
          end
        when @option_delimiter
          read_option
        else
          if char.in?(@string_delimiters) && @parse_string
            read_string
          else
            read_argument
          end
        end
      end

      validate
    end

    private def validate : MappedArgs
      validated = MappedArgs.new

      @parsed.each do |arg|
        case arg[:kind]
        when :short
          if !@short_long && arg[:name].size > 1
            raise "cannot assign value to multiple short flags" if arg[:value]
            args = arg[:name].each_char.map { |c| {kind: :short, name: c.to_s, value: nil} }.to_a
            validated += args
          else
            validated << arg
          end
        when :long
          break if arg[:name].empty?
          if !@long_short && arg[:name].size == 1
            raise "invalid long flag '#{arg[:name]}'"
          else
            validated << arg
          end
        else
          break if arg[:name] == "--"
          validated << arg
        end
      end

      validated
    end

    private def read_option : Nil
      long = false
      if @reader.peek_next_char == @option_delimiter
        long = true
        @reader.pos += 2
      else
        @reader.next_char
      end

      option = String.build do |str|
        loop do
          case char = @reader.current_char
          when '\0'
            break
          when ' '
            @reader.next_char
            break
          else
            if char.in?(@string_delimiters) && @parse_string
              str << read_string_raw
              break
            else
              str << char
              @reader.next_char
            end
          end
        end
      end

      if long
        if option.includes? '='
          name, value = option.split '='
          @parsed << {kind: :long, name: name, value: value}
        else
          @parsed << {kind: :long, name: option, value: nil}
        end
      else
        if option.includes? '='
          name, value = option.split '='
          @parsed << {kind: :short, name: name, value: value}
        else
          @parsed << {kind: :short, name: option, value: nil}
        end
      end
    end

    private def read_argument : Nil
      value = String.build do |str|
        loop do
          case char = @reader.current_char
          when '\0'
            break
          when ' '
            @reader.next_char
            break
          when '='
            raise "unexpected character '=' in argument"
          else
            str << char
            @reader.next_char
          end
        end
      end

      @parsed << {kind: :argument, name: "", value: value}
    end

    private def read_string : Nil
      @parsed << {kind: :argument, name: "", value: read_string_raw}
    end

    private def read_string_raw : String
      delim = @reader.current_char
      escaped = false
      @reader.next_char

      value = String.build do |str|
        loop do
          case char = @reader.current_char
          when '\0'
            raise "unterminated quote string" # TODO: optional error override?
          when '\\'
            escaped = !escaped
            @reader.next_char
          when delim
            if escaped
              escaped = false
              str << char
              @reader.next_char
            else
              @reader.next_char
              break
            end
          else
            str << char
            @reader.next_char
          end
        end
      end

      value
    end
  end
end
