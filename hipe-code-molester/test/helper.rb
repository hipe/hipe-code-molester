require 'rubygems' # wayne sequine told me this is ok in application code not library code --
                   # a) the point is moot in 1.9.2 b) this is for running it in 1.8.7
# require 'ruby-debug'

cm_core = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(cm_core) unless $LOAD_PATH.include?(cm_core)

require 'hipe-code-molester'
require 'minitest/unit'

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

require 'minitest/autorun'
