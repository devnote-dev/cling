require "./spec_helper"

describe CLI::Option do
  it "parses a long option" do
    opt = CLI::Option.new "spec"
    opt.long.should eq "spec"
    opt.short.should be_nil

    opt.is?("spec").should be_true
  end

  it "parses a short option" do
    opt = CLI::Option.new "spec", 's'
    opt.long.should eq "spec"
    opt.short.should eq 's'

    opt.is?("s").should be_true
  end

  it "compares options" do
    opt1 = CLI::Option.new "spec", 's'
    opt2 = CLI::Option.new "flag", 'f'

    opt1.should_not eq opt2
    opt1.should eq opt1.dup
  end
end
