require 'ruby_parser'
require 'pp'

module Hipe::CodeMolester
  class Parse < MyCommand
    description "try a parse i guess"
    parameter :file, "the file to parse", :positional => 1, :required => 1
    parameter :not_pretty, '-P', 'not pretty: calls to_s on the tree, not PP.pp'
    def execute
      File.exist?(param(:file)) or return error(:no_file, "no file: #{param(:file)}")
      contents = File.read(param(:file))
      sexp = RubyParser.new.parse contents
      if @param[:not_pretty]
        out sexp.to_s
      else
        PP.pp(sexp, outs)
      end
    end
  end
end
