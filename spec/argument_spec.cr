require "./spec_helper"

describe Cling::Argument do
  it "parses an argument" do
    argument = Cling::Argument.new "spec", "a test argument"

    argument.name.should eq "spec"
    argument.description.should eq "a test argument"
    argument.required?.should be_false
    argument.value.should be_nil
  end
end
