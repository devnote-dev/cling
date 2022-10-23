module CLI
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

    # Represents the kind of the result.
    enum ResultKind
      Argument
      ShortFlag
      LongFlag
    end

    # The result of a parsed value from the command line. This can be a normal argument, string
    # argument, short flag, or long flag.
    class Result
      property kind : ResultKind
      property value : String
      getter? string : Bool

      def initialize(@kind, @value, *, @string = false)
      end

      # Returns the key form of the value for flag results, or `value` for argument results.
      def parse_value : String
        if @value.includes? '='
          @value.split('=', 2).first
        else
          @value
        end
      end
    end

    @reader : Char::Reader
    @options : Options

    def initialize(input : String, @options : Options = Options.new)
      @reader = Char::Reader.new input
    end

    def self.new(input : Array(String), options : Options = Options.new)
      args = input.map do |a|
        if a.includes?(' ') && options.string_delims.none? { |d| a.includes?(d) }
          d = options.string_delims.first
          d.to_s + a + d.to_s
        else
          a
        end
      end

      new args.join(' '), options
    end

    # Parses the command line arguments from the reader and returns a hash of the results.
    def parse : Hash(Int32, Result)
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
      results.each do |res|
        unless res.kind.short_flag?
          validated << res
          next
        end

        if res.parse_value.size > 1
          if res.value.includes? '='
            flags = res.parse_value.chars.map { |c| Result.new(:short_flag, c.to_s) }
            opt = flags[-1]
            opt.value += "=" + res.value.split('=', 2).last
            flags[-1] = opt
            validated += flags
          else
            validated += res.value.chars.map { |c| Result.new(:short_flag, c.to_s) }
          end
        else
          validated << res
        end
      end

      validated.each_with_index.map { |r, i| {i, r} }.to_h
    end

    private def read_option : Result
      long = false
      if @reader.peek_next_char == @options.option_delim
        long = true
        @reader.pos += 2
      else
        @reader.next_char
      end

      value = String.build do |str|
        loop do
          case char = @reader.current_char
          when '\0'
            break
          when ' '
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

      Result.new((long ? ResultKind::LongFlag : ResultKind::ShortFlag), value)
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

      Result.new :argument, value
    end

    private def read_string : Result
      Result.new :argument, read_string_raw, string: true
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
