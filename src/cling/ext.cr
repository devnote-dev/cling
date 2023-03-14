module Cling
  struct Value
    {% if @top_level.has_constant?("BigInt") %}
      # Returns the value as a `BigInt`.
      def as_big : BigInt
        BigInt.new @raw.to_s
      end
    {% end %}

    # Returns the value as a `Dir` object. Note that this will raise an exception if the directory
    # is not found.
    def as_dir : Dir
      Dir.new as_path
    end

    # Returns the value as a `File` object. Note that this will raise an exception if the file is
    # is not found.
    def as_file : File
      File.open as_path
    end

    # Returns the value as a `Path` object. This will attempt to resolve the value into a valid
    # path (see `Path.new`).
    def as_path : Path
      Path.new @raw.to_s
    end

    # Returns the value as a `Set`. Note that this does not change the type of the set.
    def as_set : Set(String)
      as_a.to_set
    end

    # Returns the value as a `Time` object. This will attempt to parse the value according to the
    # matching time format, otherwise it will raise an exception (see `Time.new`).
    def as_time : Time
      Time.new @raw.to_s
    end
  end
end
