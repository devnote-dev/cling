require "./spec_helper"

private class GreetCommand < Cling::Command
  def setup : Nil
    @name = "greet"
    @description = "Greets a person"

    add_argument "name", description: "the name of the person", required: true
    add_option 'c', "caps", description: "greet with caps"
  end

  def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Bool?
    return if arguments.has? "name"
    stdout.puts Cling::Formatter.new.generate self

    false
  end

  def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
    message = %(Hello, #{arguments.get "name"}!)

    if options.has? "caps"
      stdout.puts message.upcase
    else
      stdout.puts message
    end
  end

  def on_error(ex : Exception)
    # override default behaviour so that it works in specs
    raise ex
  end
end

command = GreetCommand.new

describe Cling do
  it "tests the help command" do
    io = IO::Memory.new
    command.stdout = io
    command.execute "" rescue nil

    io.to_s.should eq <<-HELP
      Greets a person

      Usage:
      \tgreet <arguments> [options]

      Arguments:
      \tname    the name of the person (required)

      Options:
      \t-c, --caps    greet with caps

      HELP
  end

  it "tests the main command" do
    io = IO::Memory.new
    command.stdout = io
    command.execute %w(Dev) rescue nil

    io.to_s.should eq "Hello, Dev!\n"
  end

  it "tests the main command with flag" do
    io = IO::Memory.new
    command.stdout = io
    command.execute %w(-c Dev)

    io.to_s.should eq "HELLO, DEV!\n"
  end
end
