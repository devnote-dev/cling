require "./spec_helper"

describe CLI::Value do
  it "parses a value" do
    CLI::Value.new("foo").should be_a CLI::Value
    CLI::Value.new(123_i64).should be_a CLI::Value
    CLI::Value.new(4.56).should be_a CLI::Value
    CLI::Value.new(true).should be_a CLI::Value
    CLI::Value.new(nil).should be_a CLI::Value

    # currently broken
    # CLI::Value.new(%w[foo bar baz]).should be_a CLI::Value
  end

  it "compares values" do
    CLI::Value.new("foo").should eq "foo"
    CLI::Value.new(123).should eq 123
    CLI::Value.new(4.56).should eq 4.56
    CLI::Value.new(true).should eq true
    CLI::Value.new(nil).should eq nil

    # also broken
    # CLI::Value.new(%[foo bar baz]).should eq ["foo", "bar", "baz"]
  end

  it "asserts types" do
    CLI::Value.new("foo").as_s.should be_a String
    CLI::Value.new(123).as_i32.should be_a Int32
    CLI::Value.new(4.56).as_f64.should be_a Float64
    CLI::Value.new(true).as_bool.should be_true
    CLI::Value.new(nil).as_nil.should be_nil
  end
end
