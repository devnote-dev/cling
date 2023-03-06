# Cling

Based on [spf13/cobra](https://github.com/spf13/cobra), Cling is built to be almost entirely modular, giving you absolute control over almost everything without the need for embedded macros - there isn't even a default help command or flag!

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  cling:
    github: devnote-dev/cling
```

2. Run `shards install`

## Basic Usage

```crystal
require "cling"

class MainCommand < Cling::Command
  def setup : Nil
    @name = "greet"
    @description = "Greets a person"
    add_argument "name", description: "the name of the person to greet", required: true
    add_option 'c', "caps", description: "greet with capitals"
    add_option 'h', "help", description: "sends help information"
  end

  def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Bool
    if options.has? "help"
      puts help_template # generated using Cling::Formatter

      false
    else
      true
    end
  end

  def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
    message = "Hello, #{arguments.get("name")}!"

    if options.has? "caps"
      puts message.upcase
    else
      puts message
    end
  end
end

main = MainCommand.new
main.execute ARGV
```

```
$ crystal greet.cr -h
Usage:
        greet <arguments> [options]

Arguments:
        name    the name of the person to greet (required)

Options:
        -c, --caps  greet with capitals
        -h, --help  sends help information

$ crystal greet.cr Dev
Hello, Dev!

$ crystal greet.cr -c Dev
HELLO, DEV!
```

## Commands

By default, the `Command` class is initialized with almost no values. All information about the command must be defined in the `setup` method.

```crystal
class MainCommand < Cling::Command
  def setup : Nil
    @name = "greet"
    @description = "Greets a person"
    # defines an argument
    add_argument "name", description: "the name of the person to greet", required: true
    # defines a flag option
    add_option 'c', "caps", description: "greet with capitals"
    add_option 'h', "help", description: "sends help information"
  end
end
```

> **Note**
> See [command.cr](/src/cling/command.cr) for the full list of options.

Commands can also contain children, or subcommands:

```crystal
require "cling"
# import our subcommand here
require "./welcome_command"

# using the `MainCommand` created earlier
main = MainCommand.new
main.add_command WelcomeCommand.new
# there is also the `add_commands` method for adding multiple
# subcommands at one time

# run the command
main.execute ARGV
```

```$ crystal greet.cr -h
Usage:
        greet <arguments> [options]

Commands:
        welcome    sends a friendly welcome message

Arguments:
        name    the name of person to greet (required)

Options:
        -c, --caps  greet with capitals
        -h, --help  sends help information

$ crystal greet.cr welcome Dev
Welcome to the CLI world, Dev!
```

As well as being able to have subcommands, they can also inherit certain properties from the parent command:

```crystal
# in welcome_command.cr ...
class WelcomeCommand < Cling::Command
  def setup : Nil
    # ...

    # this will inherit the header and footer properties
    @inherit_borders = true
    # this will NOT inherit the parent flag options
    @inherit_options = false
    # this will inherit the input, output and error IO streams
    @inherit_streams = true
  end
end
```

## Arguments and Options

Arguments and flag options can be defined in the `setup` method of a command using the `add_argument` and `add_option` methods respectively.

```crystal
class MainCommand < Cling::Command
  def setup : Nil
    add_argument "name",
      # sets a description for it
      description: "the name of the person to greet",
      # set it as a required or optional argument
      required: true,
      # allow multiple values for the argument
      multiple: false

    # define an option with a short flag using chars
    add_option 'c', "caps",
      # sets a description for it
      description: "greet with capitals",
      # set it as a required or optional flag
      required: false,
      # the type of option it is, can be:
      # :none to take no arguments
      # :single to take one argument
      # or :array to take multiple arguments
      type: :none,
      # optionally set a default value
      default: nil
  end
end
```

> **Warning**
> You can only have **one** argument with the `multiple` option which will include all the remaining input arguments (or unknown arguments).

These arguments and options can then be accessed at execution time via the `arguments` and `options` parameters in the `pre_run`, `run` and `post_run` methods of a command:

```crystal
class MainCommand < Cling::Command
  # ...

  def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Bool # can also be `Nil`
    if arguments.get("name").as_s.blank?
      stderr.puts "Your name can't be blank!"

      false
    else
      true
    end
  end
end
```

The `pre_run` method is slightly different to the other run methods: it allows returning a boolean to the command executor, which will determine whether the command should continue running – `false` will stop the command, `true` will continue. Explicitly returning `nil` or not specifying a return type is the same as returning `true`, the command will continue to run.

If you try to access the value of an argument or option that isn't set, it will raise a `ValueNotFound` exception. To avoid this, use the `get?` method and check accordingly:

```crystal
# ...

def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
  caps = options.get?("caps").try(&.as_bool) || false
  stdout.puts caps # => false
end
```

> **Note**
> See [argument.cr](/src/cling/argument.cr#L34) and [option.cr](/src/cling/option.cr#L51) for more information on parameter methods, and [value.cr](/src/cling/value.cr) for value methods.

## Customising

The help template is divided into the following sections:

```
[HEADER]

[DESCRIPTION]

[USAGE]
    <NAME> <USE | "[<arguments>]" "[<options>]">

[COMMANDS]
    [ALIASES] <NAME> <SUMMARY>

[ARGUMENTS]
    <NAME> <DESCRIPTION> ["(required)"]

[OPTIONS]
    [SHORT] <LONG> <DESCRIPTION> ["(required)"] ["(default: ...)"]

[FOOTER]
```

Sections in `<>` will always be present, and ones in `[]` are optional depending on whether they are defined. Because of Cling's modularity, this means that you could essentially have a blank help template (wouldn't recommend it though).

You can customise the following options for the help template formatter:

```crystal
class Cling::Formatter::Options
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
require "cling"

options = Cling::Formatter::Options.new option_delim: '+', show_defaults: false
# we can re-use this in multiple commands
formatter = Cling::Formatter.new options

class MainCommand < Cling::Command
  # ...

  def help_template : String
    formatter.generate self
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

## Motivation

Most Crystal CLI builders/DSLs are opinionated with limited customisation available. Cling aims to be entirely modular so that you have the freedom to change whatever you want without having to write tons of boilerplate or monkey-patch code. Macro-based CLI shards can also be quite restrictive as they are not scalable, meaning that you may eventually have to refactor your application to another CLI shard. This is not meant to discourage you from using macro-based CLI shards, they are still useful for short and simple applications with a general template, but if you are looking for something to handle larger applications with guaranteed stability and scalability, Cling is the library for you.

## Contributing

1. Fork it (<https://github.com/devnote-dev/cling/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Devonte W](https://github.com/devnote-dev) - creator and maintainer

This repository is managed under the Mozilla Public License v2.

© 2022-present devnote-dev
