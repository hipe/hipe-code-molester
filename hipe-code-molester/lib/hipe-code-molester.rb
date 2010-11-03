# require 'filetuils'
require 'ruby_parser'
require 'ruby2ruby'

module Hipe; end
class Hipe::CodeMolester
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
  # might create a 'state table' but why?
end

class Hipe::CodeMolester
  def file path, &block
    @sexp = nil
    @path = path
    @fh = File.open(path)
    yield self if block_given?
    self
  end
  def file! path, &block
    @sexp = nil
    @path = path
    if ! File.exist?(path)
      FileUtils.touch(path)
    end
    yield self if block_given?
    self
  end
end
