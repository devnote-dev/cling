require "./application"
require "./argument"
require "./command"
require "./option"
require "./parser"

module CLI
  VERSION = "0.1.0"

  enum ValueKind
    None
    String
    # Array
  end

  def self.parse(input : String | Array(String), & : Application ->) : Nil
    app = Application.new
    yield app
    app.run input
  end
end
