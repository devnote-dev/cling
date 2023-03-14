require "./spec_helper"

private class TestArgsCommand < Cling::Command
  def setup : Nil
    @name = "main"

    add_argument "first", required: true
    add_argument "second", multiple: true
    add_option 's', "skip"
  end

  def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Bool
    !options.has?("skip")
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
    add_option 'n', "num", type: :multiple, default: %w()
  end

  def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
    options.get? "foo"
    options.get "double-foo"
    options.get('b').as_s
    options.get('n').as_a
  end
end

arguments_command = TestArgsCommand.new
options_command = TestOptionsCommand.new

describe Cling::Command do
  it "executes the pre_run only" do
    arguments_command.execute %w(--skip)
  end

  it "fails on missing arguments" do
    expect_raises Cling::CommandError do
      arguments_command.execute ""
    end
  end

  it "executes without errors" do
    arguments_command.execute %w(foo bar)
    arguments_command.execute %w(foo bar baz qux)
  end

  it "raises on unknown values" do
    expect_raises Cling::ValueNotFound do
      arguments_command.execute %w(foo)
    end
  end

  it "fails on missing options" do
    expect_raises Cling::CommandError do
      options_command.execute ""
    end
  end

  it "executes without errors" do
    options_command.execute %w(--double-foo --bar=true)
  end

  it "fails on unknown options" do
    expect_raises Cling::CommandError do
      options_command.execute %w(--double-foo --double-bar)
    end
  end

  it "fails on invalid options" do
    expect_raises Cling::ExecutionError do
      options_command.execute %w(--foo=true --double-foo)
    end
  end
end
