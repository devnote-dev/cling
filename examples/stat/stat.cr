require "../../src/cling"
require "../../src/cling/ext"

class StatCommand < Cling::MainCommand
  def setup : Nil
    super

    @name = "stat"
    @description = "Gets the stat information of a file"

    add_argument "path", description: "the path of the file to stat", required: true
  end

  def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
    path = arguments.get("path").as_path

    if File.exists? path
      info = File.info path
      stdout.puts <<-INFO
        name:        #{path.basename}
        size:        #{info.size}
        directory:   #{info.directory?}
        symlink:     #{info.symlink?}
        permissions: #{info.permissions}
        INFO
    else
      stderr.puts "No file found at that path"
    end
  end
end

StatCommand.new.execute ARGV
