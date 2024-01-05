require "./spec_helper"

# Inspired by Clim

private class ContextCommand < Cling::Command
  def setup : Nil
    @name = "context"
    @description = "Runs the Crystal context tool"
  end

  def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
    stdout.puts "Fake crystal context command!"
  end
end

private class FormatCommand < Cling::Command
  def setup : Nil
    @name = "format"
    @description = "Runs the Crystal format tool"
  end

  def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
    stdout.puts "Fake crystal format command!"
  end
end

private class CrystalCommand < Cling::MainCommand
  def setup : Nil
    super

    @description = "Runs some Crystal commands"
  end

  def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
  end

  def on_error(ex : Exception)
    # override default behaviour so that it works in specs
    raise ex
  end
end

command = CrystalCommand.new
command.add_command ContextCommand.new
command.add_command FormatCommand.new

describe Cling::MainCommand do
  it "prints the help message" do
    io = IO::Memory.new
    command.stdout = io
    command.execute "" rescue nil

    io.to_s.chomp.should eq <<-HELP
      Runs some Crystal commands

      Usage:
      \tmain [options]

      Commands:
      \tcontext
      \tformat

      Options:
      \t-h, --help       sends help information
      \t-v, --version    sends the app version
      HELP
  end

  it "runs the context command" do
    io = IO::Memory.new
    command.children["context"].stdout = io
    command.execute "context"

    io.to_s.should eq "Fake crystal context command!\n"
  end

  it "runs the format command" do
    io = IO::Memory.new
    command.children["format"].stdout = io
    command.execute "format"

    io.to_s.should eq "Fake crystal format command!\n"
  end
end
