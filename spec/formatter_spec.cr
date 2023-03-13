require "./spec_helper"

private class GreetCommand < Cling::MainCommand
  def setup : Nil
    super

    @name = "greet"
    @description = "Greets a person"

    add_argument "name", description: "the name of the person", required: true
    add_option 'c', "caps", description: "greet with caps"
  end

  def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
  end
end

command = GreetCommand.new
formatter = Cling::Formatter.new

describe Cling::Formatter do
  it "generates a help template" do
    formatter.generate(command).chomp.should eq <<-HELP
    Greets a person

    Usage:
    #{'\t'}greet <arguments> [options]

    Arguments:
    #{'\t'}name    the name of the person (required)

    Options:
    #{'\t'}-h, --help       sends help information
    #{'\t'}-v, --version    sends the app version
    #{'\t'}-c, --caps       greet with caps
    HELP
  end

  it "generates with a custom delimiter" do
    formatter.options.option_delim = '+'

    formatter.generate(command).chomp.should eq <<-HELP
    Greets a person

    Usage:
    #{'\t'}greet <arguments> [options]

    Arguments:
    #{'\t'}name    the name of the person (required)

    Options:
    #{'\t'}+h, ++help       sends help information
    #{'\t'}+v, ++version    sends the app version
    #{'\t'}+c, ++caps       greet with caps
    HELP
  end

  it "generates a description section" do
    String.build do |io|
      formatter.format_description(command, io)
    end.should eq "Greets a person\n\n"
  end

  it "generates a usage section" do
    String.build do |io|
      formatter.format_usage(command, io)
    end.should eq "Usage:\n\tgreet <arguments> [options]\n\n"
  end

  it "generates an arguments section" do
    String.build do |io|
      formatter.format_arguments(command, io)
    end.should eq "Arguments:\n\tname    the name of the person (required)\n\n"
  end

  it "generates an options section" do
    formatter.options.option_delim = '-'

    String.build do |io|
      formatter.format_options(command, io)
    end.chomp.should eq <<-HELP
    Options:
    #{'\t'}-h, --help       sends help information
    #{'\t'}-v, --version    sends the app version
    #{'\t'}-c, --caps       greet with caps

    HELP
  end
end
