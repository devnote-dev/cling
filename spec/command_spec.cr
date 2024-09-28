require "./spec_helper"

private class TestArgsCommand < Cling::Command
  def setup : Nil
    @name = "main"

    add_argument "first", required: true
    add_argument "second", multiple: true
    add_option 's', "skip"
  end

  def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Nil
    exit_program 0 if options.has? "skip"
  end

  def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
    arguments.get "first"
    arguments.get "second"
  end
end

private class TestOptionsCommand < Cling::Command
  def setup : Nil
    @name = "main"

    add_option "foo"
    add_option "double-foo", required: true
    add_option 'b', "bar", type: :single, required: true
    add_option 'n', "num", type: :multiple, default: %w[]
  end

  def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
    options.get? "foo"
    options.get "double-foo"
    options.get('b').as_s
    options.get('n').as_a
  end
end

private class TestHooksCommand < Cling::Command
  def setup : Nil
    @name = "main"

    add_argument "foo", required: true
    add_option "double-foo", required: true
    add_option 'b', "bar", type: :single
    add_option 'n', "num", type: :multiple, default: %w[]
  end

  def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
  end

  def on_missing_arguments(arguments : Array(String))
    stderr.puts arguments.join ", "
  end

  def on_unknown_arguments(arguments : Array(String))
    stderr.puts arguments.join ", "
  end

  def on_invalid_option(message : String)
    stderr.puts message
  end

  def on_missing_options(options : Array(String))
    stderr.puts options.join ", "
  end

  def on_unknown_options(options : Array(String))
    stderr.puts options.join ", "
  end
end

private class TestErrorsCommand < Cling::Command
  def setup : Nil
    @name = "main"

    add_option "fail-fast"
  end

  def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
    if options.has? "fail-fast"
      exit_program
    else
      raise "failed slowly"
    end
  end
end

arguments_command = TestArgsCommand.new
options_command = TestOptionsCommand.new
hooks_command = TestHooksCommand.new
errors_command = TestErrorsCommand.new

describe Cling::Command do
  it "executes the pre_run only" do
    arguments_command.execute("--skip").should eq 0
  end

  it "fails on missing arguments" do
    expect_raises Cling::ExecutionError, "Error while executing command error handler:\n\
      Missing required argument: first" do
      arguments_command.execute ""
    end
  end

  it "executes without errors" do
    arguments_command.execute("foo bar").should eq 0
    arguments_command.execute("foo bar baz qux").should eq 0
  end

  it "fails on unknown values" do
    expect_raises Cling::ExecutionError, "Error while executing command error handler:\n\
      Value not found for key: second" do
      arguments_command.execute "foo"
    end
  end

  it "fails on missing options" do
    expect_raises Cling::ExecutionError, "Error while executing command error handler:\n\
      Missing required options: double-foo, bar" do
      options_command.execute ""
    end
  end

  it "executes without errors" do
    options_command.execute("--double-foo --bar=true").should eq 0
  end

  it "fails on unknown options" do
    expect_raises Cling::ExecutionError, "Error while executing command error handler:\n\
      Unknown option: double-bar" do
      options_command.execute "--double-foo --double-bar"
    end
  end

  it "fails on invalid options" do
    expect_raises Cling::ExecutionError, "Error while executing command error handler:\n\
      Option 'foo' takes no arguments" do
      options_command.execute "--foo=true --double-foo"
    end

    expect_raises Cling::ExecutionError, "Error while executing command error handler:\n\
      Option 'double-foo' takes no arguments" do
      options_command.execute "--double-foo=true --bar baz"
    end
  end

  it "catches missing required arguments" do
    io = IO::Memory.new
    hooks_command.stderr = io

    hooks_command.execute("--double-foo").should eq 0
    io.to_s.should eq "foo\n"
  end

  it "catches unknown arguments" do
    io = IO::Memory.new
    hooks_command.stderr = io

    hooks_command.execute("foo --double-foo bar baz").should eq 0
    io.to_s.should eq "bar, baz\n"
  end

  it "catches an invalid option" do
    io = IO::Memory.new
    hooks_command.stderr = io

    hooks_command.execute("foo --double-foo=true\n").should eq 1
    io.to_s.should eq "Option 'double-foo' takes no arguments\n"
  end

  it "catches missing required values for options" do
    io = IO::Memory.new
    hooks_command.stderr = io

    hooks_command.execute("foo --double-foo --bar").should eq 1
    io.to_s.should eq "Missing required argument for option 'bar'\n"

    io.rewind
    hooks_command.execute("foo --double-foo -n").should eq 1
    io.to_s.should eq "Missing required arguments for option 'num'\n"
  end

  it "catches exceptions for program exit and other errors" do
    errors_command.execute("--fail-fast").should eq 1

    expect_raises(Exception, "failed slowly") do
      errors_command.execute ""
    end
  end
end
