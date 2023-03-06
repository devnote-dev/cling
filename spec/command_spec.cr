require "./spec_helper"

private class MainCommand < Cling::Command
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

describe Cling::Command do
  it "executes the pre_run only" do
    command = MainCommand.new
    command.execute %w(--skip)
  end

  it "fails on missing arguments" do
    command = MainCommand.new
    expect_raises Cling::CommandError do
      command.execute %w()
    end
  end

  it "executes without errors" do
    command = MainCommand.new
    command.execute %w(foo bar)
    command.execute %w(foo bar baz qux)
  end

  it "raises on unknown values" do
    command = MainCommand.new
    expect_raises Cling::ValueNotFound do
      command.execute %w(foo)
    end
  end
end
