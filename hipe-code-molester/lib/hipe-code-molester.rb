require 'fileutils'
require 'ruby_parser'
require 'ruby2ruby'
require 'pp'

module Hipe; end
class Hipe::CodeMolester
  VERSION = '0.0.0'

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
    # @todo defn (see 4963f7)
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
    sexp = RubyParser.new.parse(str) or fail "failed to parse ruby string: #{str.inspect}"
    @sexp = sexp
    str
  end
  def defn meth_name
    @sexp.nil? and return nil
    case @sexp.first
    when :defn
      meth_name.intern == @sexp[1] ? self : nil
    when :module, :class
      defns.detect { |d| d.defn_name == meth_name }
    end
  end
  def defn! ruby_str
    ruby_str.kind_of?(CodeMolester) and ruby_str = ruby_str.ruby # experimental
    if @sexp.nil?
      ruby(ruby_str)
    elsif [:class, :module].include?(@sexp.first)
      defn = CodeMolester.new.ruby(ruby_str)
      self.class.cache! defn
      defn(defn.defn_name) and fail "Won't overwrite existing defn: #{defn.defn_name}"
      block!.push defn.sexp
      defn
    else
      fail "Can't add a defn to a #{@sexp.first.inspect}"
    end
  end
  def defns
    find_in_scope_or_block @sexp[scope_idx], :defn
  end
  def defn_name
    @sexp and @sexp[0] == :defn and @sexp[1].to_s
  end
  # parent class @todo
  def klass! const_str
    /\A[_a-z0-9]+\z/i =~ const_str or fail "Let's keep this simple: #{const_str}"
    klass = self.klass(const_str) and return klass
    new_node = s(:class, const_str.intern, nil, s(:scope))
    if @sexp.nil?
      @sexp = new_node
      self.class.cache! self
    elsif [:module, :class].include?(@sexp.first)
      block!.push new_node
      self.class.cached new_node
    else
      fail "don't know how to add class to #{@sexp.first.inspect}"
    end
  end
  def klass const_str
    @sexp or return nil
    founds = find_nodes(@sexp[2], :class)
    case founds.size
    when 0 ; nil
    when 1 ; founds.first
    # although it's possible we don't deal with multiple matches
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
  def module! str
    /\A[_a-z0-9]+\z/i =~ str or fail "Let's keep this simple: #{str}"
    if @sexp.nil?
      @sexp = s(:module, str.intern, s(:scope))
      self.class.cache!(self)
      self
    elsif (found = _module("::#{str}")).any?
      found.last
    elsif [:module, :class].include?(@sexp.first)
      block!.push s(:module, str.intern, s(:scope))
      self.module("::#{str}")
    else
      fail "won't add a module to a #{sexp.first.inspect}"
    end
  end
  # api private below
  def block!
    case @sexp[scope_idx].first
    when :scope
      case @sexp[scope_idx].length
      when 1; nublock = s(:block); @sexp[scope_idx].push(nublock); nublock
      when 2; case @sexp[scope_idx][1].first
        when :block; @sexp[scope_idx][1]
        else nublock = s(:block, @sexp[scope_idx][1]); @sexp[scope_idx][1] = nublock;
        end
      end
    end
  end
  # always returns an array
  def _module str
    is_toplevel, clean = parse_module_path(str)
    founds = []
    if is_module?
      if module_name_local == clean
        founds.push(self)
      elsif match = module_name_matcher.match(clean)
        rest = match[1] or fail("should always be a partial match with a trailing remainder.")
        founds.concat(_module(rest)) # this name should always have leading dots
      end
    end
    if is_toplevel
      modules.select{ |m| m.module_name_matcher =~ clean }.each do |m|
        founds.concat( m.module_name_local == clean ? [m] : m._module(str) )
      end
    else
      founds.concat modules.map{ |m| m._module(str) }.flatten
    end
    founds
  end
  def colon2_to_str node
    case node.first
    when :const  ; node[1].to_s
    when :colon2 ; "#{colon2_to_str(node[1])}::#{node[2]}"
    else fail "nevar: #{node.first.inspect}" # keep this here. callers expect it
    end
  end
  def is_module?
    @sexp && [:module, :class].include?(@sexp.first) # experimental munging of class into this
  end
  def module_name_matcher
    /\A#{Regexp.escape(module_name_local)}\b(.+)?\Z/ # better to be safe and not cache this
  end
  def module_name_local
    is_module? or return nil
    case @sexp[1]
    when Symbol ; @sexp[1].to_s
    else        ; colon2_to_str(@sexp[1])
    end
  end
  def modules
    case @sexp.first
    when :module, :class # quietly treat class as module -- experimental!
      case @sexp[scope_idx].first
      when :scope
        if @sexp[scope_idx].size == 1
          []  # emtpy scope
        else
          case @sexp[scope_idx][1][0]
          when :block
            modules_in_node(@sexp[scope_idx][1])
          when :module, :class # include class as module -- experimental!
            [self.class.cached(@sexp[scope_idx][1])]
          when :defn
            []
          else
            fail "do me: #{@sexp[scope_idx][1][0].inspect}"
          end
        end
      else
        fail "do me: ..."
      end
    when :block
      modules_in_node(@sexp)
    else
      fail "do me: #{@sexp.first.inspect}"
    end
  end
  def modules_in_node sexp
     find_nodes sexp, :module
  end
  def find_nodes sexp, type
    sexp.select{ |s| Sexp === s and s.first == type }.map{ |s| self.class.cached(s) }
  end
  def find_in_scope_or_block sexp, type
    [:block, :scope].include?(sexp.first) && sexp.size == 1 and return []
    :block == sexp[1].first and sexp = sexp[1]
    find_nodes sexp, type
  end
  def parse_module_path str
    md = /\A(::)?([a-z0-9_]+(?:::[a-z0-9_]+)*)\z/i.match(str) or fail "bad module path: #{str.inspect}"
    md.captures # 068a0e56 used to do more
  end
  def scope_idx
    case @sexp.first
    when :module ; 2
    when :class  ; 3
    end
  end
  @@cache = {}
  class << self
    def cache! code_molester
      sexp = code_molester.sexp
      @@cache.key?(sexp.object_id) and fail "already cached sexp: #{sexp.first.inspet}##{sexp.object_id}"
      @@cache[sexp.object_id] = code_molester
    end
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
