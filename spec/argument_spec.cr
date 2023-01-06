require "./spec_helper"

describe CLI::Argument do
  it "parses an argument" do
    argument = CLI::Argument.new "spec", "a test argument"

    argument.name.should eq "spec"
    argument.description.should eq "a test argument"
    argument.required?.should be_false
    argument.value.should be_nil
  end
end
