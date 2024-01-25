require "./cling/argument"
require "./cling/command"
require "./cling/errors"
require "./cling/executor"
require "./cling/formatter"
require "./cling/helper"
require "./cling/option"
require "./cling/parser"
require "./cling/value"

module Cling
  VERSION = "3.0.0"
end

# TODO: move this to cling/spec
{% if @top_level.has_constant?("Spec") %}
  module Cling::Executor
    private def self.handle_exit(ex : Cling::ExitProgram) : Nil
    end
  end
{% end %}
