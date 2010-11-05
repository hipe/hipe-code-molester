require File.expand_path('../../config/environment', __FILE__)
require 'tempfile'
require 'fileutils'
require 'hipe-code-molester'
require 'minitest/unit'

CodeMolester = Hipe::CodeMolester

# supreme and ugly hack to get minitest to run the tests in the order they were defined
# when --seed='' is passed, only for more sane un-regressing (simplests tests first)

if (idx = ARGV.index{ |x| x =~ /\A--seed\b/ } and (ARGV[idx] == '--seed=' || ARGV[idx+1] == ''))
  class << MiniTest::Unit::TestCase
    alias_method :orig_test_methods, :test_methods
    def defn_order
      @defn_order ||= []
    end
    def test_methods
      if :unsorted == test_order
        if defn_order.any?
          order = defn_order
          public_instance_methods(true).grep(/^test/).
            map  { |m| m.to_s }.
            sort { |a, b| order.index(a) < order.index(b) ? -1 : 1 }
        else
          public_instance_methods(true).grep(/^test/) # annoy
        end
      else
        orig_test_methods
      end
    end
    def test_order
      :unsorted
    end
    def method_added meth
      if /\Atest/ =~ meth.to_s
        defn_order.push meth.to_s
      end
    end
  end
  (ARGV[idx] == '--seed=') ? (ARGV[idx] = '--seed=0') : (ARGV[idx+1] = '0') # careful, aesthetics
end

module MolesterTester
  @verbose = true
  @dir_counter = 0
  class << self
    attr_accessor :dir_counter
    attr_reader   :verbose
  end
  def dir_counter;    MolesterTester.dir_counter     end
  def dir_counter= x; MolesterTester.dir_counter = x end
  def verbose?;       MolesterTester.verbose         end
  def next_empty_tmpdir
    dir = "#{Dir.tmpdir}/molest-#{self.dir_counter += 1}"
    File.directory?(dir) || FileUtils.mkdir(dir, :verbose => verbose?)
    unless Dir["#{dir}/*"].empty?
      Dir["#{dir}/*"].each do |path|
        @verbose and $stdout.puts("rm -rf #{path}")
        FileUtils.remove_entry_secure(path)
      end
    end
    dir
  end
end

require 'minitest/autorun'
