require 'fileutils'
require 'ruby_parser'
require 'ruby2ruby'
require 'pp'
require 'strscan'

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
  def initialize
    @sexp = nil        # yeah
  end
  attr_reader :sexp
  def file path, &block
    @sexp = nil
    @path = path
    str = File.read(path)
    self.ruby = str
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
  def ruby *a
    case a.size
    when 1 ; self.ruby= a.first; return self;
    when 0 ; # fallthrough
    else raise ArgumentError.new("0 or 1 argument")
    end
    Ruby2RubyMolested.new.process @sexp.deep_clone # sexp_processor
  end
  def ruby= str
    sexp = RubyParser.new.parse(str) or fail("huh?")
    @sexp = sexp
    str
  end
  def module? *a
    case a.size
    when 0 ; return is_module?
    when 1 ; # fallthrough!
    else  raise ArgumentError.new("expecting 0 or 1 arg, not #{a.count}")
    end
  end
  def module str
    @sexp.nil? and return nil
    founds = _module(str)
    case founds.size  # experimental return values!
    when 0 ; nil
    when 1 ; founds.first
    else founds
    end
  end
  # always returns an array
  def _module str
    is_toplevel, first, rest, full = parse_module_path(str)
    founds = []
    if module?
      case module_name_local
      when full  ; founds.push(self)
      when first ; rest and  founds.concat(_module(rest))
      end
    end
    founds.concat modules.map{ |m| m._module(str) }.flatten
    founds
  end
# api private below
  def colon2_to_str node
    case node.first
    when :const  ; node[1].to_s
    when :colon2 ; "#{colon2_to_str(node[1])}::#{node[2]}"
    else fail("nevar: #{node.first.inspect}") # keep this here. callers expect it
    end
  end
  def is_module?
    @sexp && @sexp.first == :module
  end
  def module_name_local
    return nil unless @sexp && @sexp.first == :module
    case @sexp[1]
    when Symbol ; @sexp[1].to_s
    else        ; colon2_to_str(@sexp[1])
    end
  end
  def modules
    case @sexp.first
    when :module
      case @sexp[2][0]
      when :scope
        if @sexp[2].size == 1
          []  # emtpy scope
        else
          case @sexp[2][1][0]
          when :block
            modules_in_node(@sexp[2][1])
          when :module
            [self.class.cached(@sexp[2][1])]
          else
            fail("do me .. ")
          end
        end
      else
        fail("do me: ...")
      end
    when :block
      modules_in_node(@sexp)
    else
      fail("do me: #{@sexp.first.inspect}")
    end
  end
  def modules_in_node sexp
    sexp.select{ |s| Sexp === s and s.first == :module }.map{ |s| self.class.cached(s) }
  end
  def parse_module_path str
    md = /\A(::)?([a-z0-9_]+(?:::[a-z0-9_]+)*)\z/i.match(str) or fail("bad module path: #{str.inspect}")
    scn = StringScanner.new(md[2])
    first = scn.scan(/[^:]+/)
    rest = ( '' == scn.rest ? nil : scn.rest )
    [md[1], first, rest, md[2]]
  end
  @@cache = {}
  class << self
    def cached sexp
      @@cache[sexp.object_id] ||= new_child(sexp)
      @@cache[sexp.object_id]
    end
    def new_child sexp
      child = allocate
      child.instance_variable_set('@sexp', sexp)
      child
    end
  end
end
