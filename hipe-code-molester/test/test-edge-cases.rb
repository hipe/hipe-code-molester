require File.dirname(__FILE__) + '/helper.rb'

class TestFileMolestation < MiniTest::Unit::TestCase
  include MolesterTester
  def setup
    @cm = CodeMolester.new
  end
  def test_error_with_ruby
    assert_raises(ArgumentError) do
      @cm.ruby('one', 'two')
    end
  end
  def test_error_with_module?
    assert_raises(ArgumentError) do
      @cm.module?('Foo')
    end
  end
  def test_colon2_to_str
    assert_raises(RuntimeError) do
      @cm.colon2_to_str(s(:class, :Foo))
    end
  end
  def test_module_wierd_scope
    @cm.instance_variable_set('@sexp', s(:module, :Foo, s(:scope, s(:baz))))
    e = assert_raises(RuntimeError) do
      @cm.modules
    end
    assert_match(/do me/, e.message)
  end
  def test_module_no_scope
    @cm.instance_variable_set('@sexp', s(:module, :Foo, s(:dope)))
    e = assert_raises(RuntimeError) do
      @cm.modules
    end
    assert_match(/do me:/, e.message)
  end
  def test_module_no_block
    @cm.instance_variable_set('@sexp', s(:dodule, :Foo))
    e = assert_raises(RuntimeError) do
      @cm.modules
    end
    assert_match(/do me:/, e.message)
  end
end
