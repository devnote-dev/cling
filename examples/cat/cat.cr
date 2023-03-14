require "../../src/cling"
require "../../src/cling/ext"

class CatCommand < Cling::MainCommand
  def setup : Nil
    super

    @name = "cat"
    @description = "Concatenates one or more files"

    add_argument "files", description: "the files to concatenate", required: true, multiple: true
  end

  def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Bool
    files = arguments.get? "files"
    unless files
      stdout.puts help_template
      return false
    end

    files.as_set.each do |path|
      stderr.puts "file '#{path}' not found" unless File.exists? path
    end

    true
  end

  def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
    paths = arguments.get("files").as_set.select { |p| File.exists? p }
    return if paths.empty?

    str = paths.map do |path|
      File.read path rescue ""
    end.join '\n'

    stdout.puts str
  end
end

CatCommand.new.execute ARGV
