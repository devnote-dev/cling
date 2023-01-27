require "./spec_helper"

describe Cling::Option do
  it "parses a long option" do
    option = Cling::Option.new "spec"
    option.long.should eq "spec"
    option.short.should be_nil

    option.is?("spec").should be_true
  end

  it "parses a short option" do
    option = Cling::Option.new "spec", 's'
    option.long.should eq "spec"
    option.short.should eq 's'

    option.is?("s").should be_true
  end

  it "compares options" do
    option1 = Cling::Option.new "spec", 's'
    option2 = Cling::Option.new "flag", 'f'

    option1.should_not eq option2
    option1.should eq option1.dup
  end
end
