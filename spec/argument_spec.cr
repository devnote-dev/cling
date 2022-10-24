require "./spec_helper"

describe CLI::Argument do
  it "parses an argument" do
    arg = CLI::Argument.new "spec", "a test argument"

    arg.name.should eq "spec"
    arg.description.should eq "a test argument"
    arg.required?.should be_false
    arg.value.should be_nil
  end
end
