require "./spec_helper"

describe CLI::Parser do
  it "parses standard input arguments" do
    parser = CLI::Parser.new %(these --are "some" -c arguments)
    results = parser.parse

    results[0].kind.should eq CLI::Parser::ResultKind::Argument
    results[1].kind.should eq CLI::Parser::ResultKind::LongFlag
    results[2].kind.should eq CLI::Parser::ResultKind::Argument
    results[3].kind.should eq CLI::Parser::ResultKind::ShortFlag
    results[4].kind.should eq CLI::Parser::ResultKind::Argument
  end

  it "parses custom flag input arguments" do
    opts = CLI::Parser::Options.new option_delim: '+'
    parser = CLI::Parser.new %(these ++are "some" +c arguments), opts
    results = parser.parse

    results[0].kind.should eq CLI::Parser::ResultKind::Argument
    results[1].kind.should eq CLI::Parser::ResultKind::LongFlag
    results[2].kind.should eq CLI::Parser::ResultKind::Argument
    results[3].kind.should eq CLI::Parser::ResultKind::ShortFlag
    results[4].kind.should eq CLI::Parser::ResultKind::Argument
  end

  it "parses a string argument" do
    parser = CLI::Parser.new %w(--test "string argument" -t)
    results = parser.parse

    results[0].kind.should eq CLI::Parser::ResultKind::LongFlag
    results[1].kind.should eq CLI::Parser::ResultKind::Argument
    results[1].value.should eq "string argument"
    results[2].kind.should eq CLI::Parser::ResultKind::ShortFlag
  end

  it "parses an option argument" do
    parser = CLI::Parser.new %(--name=foo -k=bar)
    results = parser.parse

    results[0].kind.should eq CLI::Parser::ResultKind::LongFlag
    results[0].value.should eq "name=foo"
    results[0].parse_value.should eq "name"

    results[1].kind.should eq CLI::Parser::ResultKind::ShortFlag
    results[1].value.should eq "k=bar"
    results[1].parse_value.should eq "k"
  end
end
