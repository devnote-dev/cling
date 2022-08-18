module CLI
  alias ParsedArg = {kind: Symbol, name: String, value: String?}

  class Parser
    @reader : Char::Reader
    @parsed : Array(ParsedArg)

    def initialize(@parse_string : Bool,
                   @string_delimiters : Array(Char),
                   @option_delimiter : Char)
      @reader = uninitialized Char::Reader
      @parsed = [] of ParsedArg
    end

    def parse(input : Array(String)) : Hash(Int32, ParsedArg)
      parse input.join(' ')
    end

    def parse(input : String) : Hash(Int32, ParsedArg)
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

    private def validate : Hash(Int32, ParsedArg)
      validated = {} of Int32 => ParsedArg

      @parsed.each_with_index do |arg, index|
        if arg[:kind] == :short
          if arg[:name].size > 1
            raise "cannot assign to multiple short flags" if arg[:value]
            flags = arg[:name].each_char.map { |c| {kind: :short, name: c.to_s, value: nil} }.to_a
            validated.merge flags.each_with_index.to_h.invert
          else
            validated[index] = arg
          end
        else
          validated[index] = arg
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
