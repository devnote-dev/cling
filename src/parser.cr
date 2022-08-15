module CLI
  alias MappedArgs = Array({Symbol, String, String?})

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

      @parsed
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
          @parsed << {:long, name, value}
        else
          @parsed << {:long, option, nil}
        end
      else
        if option.includes? '='
          name, value = option.split '='
          raise "cannot assign value to multiple short flags" if name.size > 1
          @parsed << {:short, name, value}
        else
          option.each_char { |c| @parsed << {:short, c.to_s, nil} }
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

      @parsed << {:argument, value, nil}
    end

    private def read_string : Nil
      @parsed << {:argument, "", read_string_raw}
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
