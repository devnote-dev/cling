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
    # CLI::Value.new({0 => false, 1 => true}).should be_a CLI::Value
  end

  it "compares values" do
    CLI::Value.new("foo").should eq "foo"
    CLI::Value.new(123_i64).should eq 123_i64
    CLI::Value.new(4.56).should eq 4.56
    CLI::Value.new(true).should eq true
    CLI::Value.new(nil).should eq nil

    # also broken
    # CLI::Value.new(%[foo bar baz]).should eq ["foo", "bar", "baz"]
    # CLI::Value.new({0 => false, 1 => true}).should eq({0 => false, 1 => true})
  end
end
