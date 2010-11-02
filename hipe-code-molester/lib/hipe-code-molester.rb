require 'ruby_parser'
require 'ruby2ruby'

module Hipe; end
module Hipe::CodeMolester
  class Ruby2RubyMolested < Ruby2Ruby
    def process_class sexp
      "#{sexp.comments}#{super}"
    end
    def process_module sexp
      "#{sexp.comments}#{super}"
    end
    def process_defn sexp
      "#{sexp.comments}#{super}"
    end
    def process_defs sexp
      "#{sexp.comments}#{super}"
    end
  end
end
