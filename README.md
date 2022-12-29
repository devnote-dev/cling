# CLI.cr

Yet another command line interface library for Crystal. Based on [spf13/cobra](https://github.com/spf13/cobra), CLI.cr is built to be almost entirely modular, giving you absolute control over almost everything without the need for embedded macros - there isn't even a default help command or flag!

## Installation

1. Add the dependency to your `shard.yml`:
```yaml
dependencies:
  cli:
    github: devnote-dev/cli.cr
    branch: stable
```

2. Run `shards install`

## Basic Usage

```crystal
require "cli"

class MainCmd < CLI::Command
  def setup : Nil
    @name = "greet"
    @description = "Greets a person"
    add_argument "name", desc: "the name of person to greet", required: true
    add_option 'c', "caps", desc: "greet with capitals"
    add_option 'h', "help", desc: "sends help information"
  end

  def pre_run(args, options)
    if options.has? "help"
      puts help_template # generated using CLI::Formatter

      false
    else
      true
    end
  end

  def run(args, options) : Nil
    msg = "Hello, #{args.get("name")}!"

    if options.has? "caps"
      puts msg.upcase
    else
      puts msg
    end
  end
end

main = MainCmd.new
main.execute ARGV
```

```
$ crystal greet.cr -h
Usage:
        greet <arguments> [options]

Arguments:
        name    the name of person to greet (required)

Options:
        -c, --caps  greet with capitals
        -h, --help  sends help information

$ crystal greet.cr Dev
Hello, Dev!

$ crystal greet.cr -c Dev
HELLO, DEV!
```

## Customising

You can customise the following options for the help template formatter:
```crystal
class CLI::Formatter::Options
  # The character to use for flag option delimiters (default is `-`).
  property option_delim : Char

  # Whether to show the `default` tag for options with default values (default is `true`).
  property show_defaults : Bool

  # Whether to show the `required` tag for required arguments/options (default is `true`).
  property show_required : Bool
end
```

And pass it to the command like so:
```crystal
require "cli"

options = CLI::Formatter::Options.new option_delim: '+', show_defaults: false

class MainCmd < CLI::Command
  # ...

  def help_template : String
    CLI::Formatter.new(self, options).generate
  end
end
```

Alternatively, if you want a completely custom design, you can pass a string directly:
```crystal
def help_template : String
  <<-TXT
  My custom command help text!

  Use:
      greet <name> [-c | --caps] [-h | --help]
  TXT
end
```

## Contributing
1. Fork it (<https://github.com/devnote-dev/cli.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors
- [Devonte W](https://github.com/devnote-dev) - creator and maintainer

This repository is managed under the Mozilla Public License v2.

© 2022 devnote-dev
