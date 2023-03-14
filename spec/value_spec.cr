require "./spec_helper"

describe Cling::Value do
  it "parses a value" do
    Cling::Value.new("foo").should be_a Cling::Value
    Cling::Value.new(123_i64).should be_a Cling::Value
    Cling::Value.new(4.56).should be_a Cling::Value
    Cling::Value.new(true).should be_a Cling::Value
    Cling::Value.new(nil).should be_a Cling::Value
    Cling::Value.new(%w[foo bar baz]).should be_a Cling::Value
  end

  it "compares values" do
    Cling::Value.new("foo").should eq "foo"
    Cling::Value.new(123).should eq 123
    Cling::Value.new(4.56).should eq 4.56
    Cling::Value.new(true).should eq true
    Cling::Value.new(nil).should eq nil
    Cling::Value.new(%w[foo bar baz]).should eq ["foo", "bar", "baz"]
  end

  it "asserts types" do
    Cling::Value.new("foo").as_s.should be_a String
    Cling::Value.new(123).as_i32.should be_a Int32
    Cling::Value.new(4.56).as_f64.should be_a Float64
    Cling::Value.new(true).as_bool.should be_true
    Cling::Value.new(nil).raw.should be_nil
    Cling::Value.new(%w[]).as_a.should be_a Array(String)
  end
end
