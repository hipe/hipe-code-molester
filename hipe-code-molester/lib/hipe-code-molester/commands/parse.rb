module Hipe::CodeMolester
  class Parse < MyCommand
    description "try a parse i guess. this gains nothing over r2r_show except that i wrote it."
    parameter :file, "the file to parse", :positional => 1, :required => 1
    parameter :not_pretty, '-P', 'not pretty: calls to_s on the tree, not PP.pp'
    parameter :unparse, '-u', 'generate ruby again from the tree (-P irrelevant)'
    def execute
      File.exist?(param(:file)) or return error(:no_file, "no file: #{param(:file)}")
      contents = File.read(param(:file))
      sexp = RubyParser.new.parse contents
      if @param[:unparse]
        out Ruby2RubyMolested.new.process sexp
      elsif @param[:not_pretty]
        out sexp.to_s
      else
        PP.pp(sexp, outs)
      end
      quiet_exit
    end
    def on_success
      @quiet_exit or super
    end
  private
    def quiet_exit
      @quiet_exit = true
    end
  end
end
