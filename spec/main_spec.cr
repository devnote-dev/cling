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

    add_argument "name", description: "the name of the person", required: true
    add_option 'c', "caps", description: "greet with caps"
  end

  def pre_run(arguments : CLI::ArgumentsInput, options : CLI::OptionsInput) : Bool?
    unless arguments.has? "name"
      io.puts CLI::Formatter.new.generate self

      false
    end
  end

  def run(arguments : CLI::ArgumentsInput, options : CLI::OptionsInput) : Nil
    message = %(Hello, #{arguments.get! "name"}!)

    if options.has? "caps"
      io.puts message.upcase
    else
      io.puts message
    end
  end
end

describe CLI do
  it "tests the help command" do
    command = Greet.new
    command.execute %w()

    command.io.to_s.should eq "Greets a person\n\n" \
                              "Usage:\n\tgreet <arguments> [options]\n\n" \
                              "Arguments:\n\tname    the name of the person (required)\n\n" \
                              "Options:\n\t-c, --caps  greet with caps\n\n"
  end

  it "tests the main command" do
    command = Greet.new
    command.execute %w(Dev)

    command.io.to_s.should eq "Hello, Dev!\n"
  end

  it "tests the main command with flag" do
    command = Greet.new
    command.execute %w(-c Dev)

    command.io.to_s.should eq "HELLO, DEV!\n"
  end
end
