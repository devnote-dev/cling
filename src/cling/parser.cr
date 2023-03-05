module Cling
  # Handles parsing command line arguments into raw argument objects (see `Result`) which are used
  # by the `Executor` at execution time.
  class Parser
    # Represents options for the parser.
    class Options
      # Parse string arguments as one value instead of separate values (defaults is `true`).
      property parse_string : Bool
      # TODO
      # property parse_escape : Bool

      # The character to use for flag option delimiters (default is `-`).
      property option_delim : Char

      # The characters to accept as string delimiters (default is `"` and `'`).
      property string_delims : Set(Char)

      def initialize(*, @parse_string : Bool = true, @option_delim : Char = '-',
                     @string_delims : Set(Char) = Set{'"', '\''})
      end
    end

    # The result of a parsed value from the command line. This can be a normal argument, string
    # argument, short flag, or long flag.
    class Result
      # Represents the kind of the result.
      enum Kind
        Argument
        ShortFlag
        LongFlag
      end

      property kind : Kind
      property key : String?
      property value : String?
      getter? string : Bool

      def initialize(@kind : Kind, @key : String? = nil, @value : String? = nil, *, @string : Bool = false)
      end

      # Returns the non-nil form of the result key which is the name if it is a flag, or the value
      # if it is an argument.
      def key! : String
        @key.not_nil!
      end

      # Returns the non-nil form of the result value which is the explicit value if it is a flag,
      # or the value if it is an argument.
      def value! : String
        @value.not_nil!
      end
    end

    @reader : Char::Reader
    @options : Options

    def initialize(input : String, @options : Options = Options.new)
      @reader = Char::Reader.new input
    end

    def self.new(input : Array(String), options : Options = Options.new)
      arguments = input.map do |a|
        if a.includes?(' ') && options.string_delims.none? { |d| a.starts_with?(d) && a.ends_with?(d) }
          d = options.string_delims.first
          d.to_s + a + d.to_s
        else
          a
        end
      end

      new arguments.join(' '), options
    end

    # Parses the command line arguments from the reader and returns a hash of the results.
    def parse : Array(Result)
      results = [] of Result

      loop do
        case char = @reader.current_char
        when '\0'
          break
        when ' '
          @reader.next_char
        when '-'
          if @options.option_delim == '-'
            results << read_option
          else
            results << read_argument
          end
        when @options.option_delim
          results << read_option
        else
          if char.in?(@options.string_delims) && @options.parse_string
            results << read_string
          else
            results << read_argument
          end
        end
      end

      validated = [] of Result
      results.each do |result|
        unless result.kind.short_flag?
          validated << result
          next
        end

        if (key = result.key) && key.size > 1
          flags = key.chars.map { |c| Result.new(:short_flag, c.to_s) }
          if value = result.value
            option = flags[-1]
            option.value = value
            flags[-1] = option
          end
          validated += flags
        else
          validated << result
        end
      end

      validated
    end

    private def read_option : Result
      kind = Result::Kind::ShortFlag
      if @reader.peek_next_char == @options.option_delim
        kind = Result::Kind::LongFlag
        @reader.pos += 2
      else
        @reader.next_char
      end

      result = Result.new kind
      result.key = String.build do |str|
        loop do
          case char = @reader.current_char
          when '\0', ' ', '='
            break
          else
            if @options.string_delims.includes?(char) && @options.parse_string
              str << read_string_raw
              break
            else
              str << char
              @reader.next_char
            end
          end
        end
      end

      if @reader.current_char == '='
        @reader.next_char

        result.value = String.build do |str|
          loop do
            case char = @reader.current_char
            when '\0', ' '
              break
            else
              if @options.string_delims.includes?(char) && @options.parse_string
                str << read_string_raw
                break
              else
                str << char
                @reader.next_char
              end
            end
          end
        end
      end

      result
    end

    private def read_argument : Result
      value = String.build do |str|
        loop do
          case char = @reader.current_char
          when '\0'
            break
          when ' '
            @reader.next_char
            break
          else
            str << char
            @reader.next_char
          end
        end
      end

      Result.new :argument, nil, value
    end

    private def read_string : Result
      Result.new :argument, nil, read_string_raw, string: true
    end

    private def read_string_raw : String
      delim = @reader.current_char
      escaped = false
      @reader.next_char

      String.build do |str|
        loop do
          case char = @reader.current_char
          when '\0'
            raise ParserError.new "Unterminated quote string"
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
    end
  end
end
