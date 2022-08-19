# CLI.cr
Yet another Crystal command line interface library.

## Installation
1. Add the dependency to your `shard.yml`:
```yaml
dependencies:
  cli:
    github: devnote-dev/cli.cr
```

2. Run `shards install`

## Usage
```crystal
require "cli"

class MainCmd < CLI::Command
  def setup
    @name = "greet"
    @description = "Greets a person"
    add_argument "name", desc: "the name of person to greet", required: true
    add_option "caps", short: "c", desc: "greet with capitals"
  end

  def execute(args, options) : Nil
    msg = "Hello, #{args.get("name")}!"

    if options.has? "caps"
      puts msg.upcase
    else
      puts msg
    end
  end
end

app = CLI::Application.new
app.add_command MainCmd, default: true

app.run ARGV
```
```shell
$ crystal greet.cr -h
Greets a person

Usage:
        greet <arguments> [options]

Arguments:
        person    the person to greet

Options:
        -c, --caps  greet with capitals

$ crystal greet.cr Dev
Hello, Dev!

$ crystal greet.cr -c Dev
HELLO, DEV!
```

## Contributing
1. Fork it (<https://github.com/devnote-dev/cli.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors
- [Devonte W](https://github.com/devnote-dev) - creator and maintainer

This repository is managed under the GNU AGPL v3 license.

© 2022 devnote-dev
