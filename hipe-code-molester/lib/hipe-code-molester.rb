# require 'filetuils'
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
  def module str
    is_toplevel, const, rest = parse_module_path str
    @sexp.nil? and return nil
    case @sexp.first
    when :block
      modules =  @sexp.select{ |node| Sexp === node && node.first == :module }
      matches = modules.select{ |node| node[1] == const }
      case matches.size
      when 0 ; nil
      when 1 ;
        case modules.size
        when 1 ; rest ? self.module(rest) : self
        else   ;
          next_node = self.class.cached(matches.first)
          rest ? next_node.module(rest) : next_node
        end
      else
        children = matches.map{ |node| self.class.cached(node) }
        rest.nil? ? children : begin
          things = children.map{ |child| child.module(rest) }.compact.flatten
          things.empty? ? nil : things
        end
      end
    when :module
      if @sexp[1] != const
        nil
      else
        rest.nil? ? self : nil
      end
    else nil
    end
  end
private
  def parse_module_path str
    md = /\A(::)?([a-z0-9_]+(?:::[a-z0-9_]+)*)\z/i.match(str) or fail("bad module path: #{str.inspect}")
    scn = StringScanner.new(md[2])
    const = scn.scan(/[^:]+/).intern
    scn.scan(/::/)
    rest = ( '' == scn.rest ? nil : scn.rest )
    [md[0], const, rest]
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
