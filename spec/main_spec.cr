require "./spec_helper"

private class Greet < CLI::Command
  getter io : IO::Memory

  def initialize
    super

    @io = IO::Memory.new
  end

  def setup : Nil
    @name = "greet"
    @description = "Greets a person"

    add_argument "name", desc: "the name of the person", required: true
    add_option 'c', "caps", desc: "greet with caps"
  end

  def pre_run(args, options)
    unless args.has? "name"
      io.puts CLI::Formatter.new(self).generate

      false
    end
  end

  def run(args, options) : Nil
    msg = %(Hello, #{args.get! "name"}!)

    if options.has? "caps"
      io.puts msg.upcase
    else
      io.puts msg
    end
  end
end

describe CLI do
  it "tests the help command" do
    cmd = Greet.new
    cmd.execute %w()

    cmd.io.to_s.should eq "Greets a person\n\n" \
                          "Usage:\n\tgreet <arguments> [options]\n\n" \
                          "Arguments:\n\tname    the name of the person (required)\n\n" \
                          "Options:\n\t-c, --caps  greet with caps\n\n"
  end

  it "tests the main command" do
    cmd = Greet.new
    cmd.execute %w(Dev)

    cmd.io.to_s.should eq "Hello, Dev!\n"
  end

  it "tests the main command with flag" do
    cmd = Greet.new
    cmd.execute %w(-c Dev)

    cmd.io.to_s.should eq "HELLO, DEV!\n"
  end
end
