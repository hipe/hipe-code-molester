require File.dirname(__FILE__) + '/helper.rb'

class TestModuleMolestation < MiniTest::Unit::TestCase
  include MolesterTester
  def setup
    @cm = CodeMolester.new
  end
  def test_search_module_in_empty_block_find_none
    assert_equal nil, @cm.module('Foo')
  end
  def test_search_deep_module_in_emtpy_block_find_none
    assert_equal nil, @cm.module('Foo::Bar')
  end
  def test_search_module_abs_path_in_empty_block_find_none
    assert_equal nil, @cm.module('::Foo')
  end
  def test_search_abs_module_deep_in_empty_find_none
    assert_equal nil, @cm.module('::Foo::Bar')
  end
  def test_find_one_module_should_be_self!
    @cm.ruby('module Foo; end')
    found = @cm.module('Foo')
    assert_equal @cm.class, found.class
    assert_equal @cm.object_id, found.object_id
  end
  def test_find_one_module_absolute
    @cm.ruby('module Foo; end')
    found = @cm.module('::Foo')
    assert_equal @cm.object_id, found.object_id
  end
  def test_find_one_wrong_module_should_be_nil
    @cm.ruby('module Bar; end')
    assert_equal(nil, @cm.module('Foo'))
  end
  def test_find_two_right_among_two
    @cm.ruby <<-RUBY
      module Foo; end
      module Foo; end
    RUBY
    founds = @cm.module('Foo') # experimental
    assert_kind_of Array, founds
    assert_equal founds.size, 2
    founds2 = @cm.module('Foo')
    assert_equal founds[0].object_id, founds2[0].object_id
    assert_equal founds[1].object_id, founds2[1].object_id
  end
  def test_find_one_among_several
    @cm.ruby <<-RUBY
      module Alpha; end
      module Beta;  end
      module Gamma; end
    RUBY
    found = @cm.module('Beta')
    assert_kind_of Hipe::CodeMolester, found
    assert found.object_id != @cm.object_id, "should not return self for this"
  end
  def test_find_two_among_several
    @cm.ruby <<-RUBY
      module Alpha; end
      module Beta;  end
      module Gamma; end
      module Beta;  end
    RUBY
    found = @cm.module('Beta')
    assert_kind_of Array, found
    assert_equal 2, found.size
    assert_kind_of Hipe::CodeMolester, found.first
    assert_kind_of Hipe::CodeMolester, found.last
    assert(@cm.object_id != found.first.object_id, "different objects here")
    assert(found.first.object_id != found.last.object_id, "different objects here")
  end
  def test_not_find_one_compound
    @cm.ruby <<-RUBY
      module Foo::Bar::Baz; end
    RUBY
    assert_nil nil, @cm.module('Foo')
  end
  def test_find_one_deep_simple
    @cm.ruby <<-RUBY
      module Foo;
        module Bar; end
      end
    RUBY
    found = @cm.module('::Foo::Bar')
    assert_kind_of CodeMolester, found
    assert_equal 'Bar', found.module_name_local
    assert @cm.object_id != found.object_id
  end
  def test_find_one_deep_with_others
    @cm.ruby(<<-RUBY)
      module Foo;
        module Baz; end
        module Bar; end
      end
    RUBY
    found = @cm.module('::Foo::Bar')
    assert_kind_of CodeMolester, found
    assert_equal 'Bar', found.module_name_local
  end
  def test_two_levels_two_ways
    @cm.ruby <<-RUBY
      module Baz; end
      module Foo;
        module Bar;
          module Daft::Punk; end
        end
        module Baz;
        end
      end
    RUBY
    one = @cm.module('::Foo::Bar::Daft::Punk')
    two = @cm.module('Foo::Bar::Daft::Punk')
    assert_kind_of CodeMolester, one
    assert_kind_of CodeMolester, two
    assert_equal one.object_id, two.object_id
  end
  def test_find_recursive
    @cm.ruby <<-RUBY
      module Baz; end
      module Foo
        module Bar
          module Baz; end
        end
      end
      module Bar
        module Baz
        end
      end
      module Bar::Baz
        def blah; end
      end
    RUBY
    these = @cm.module('Bar::Baz')
    assert_kind_of Array, these
    assert_equal 3, these.size
    assert_equal 3, these.map(&:object_id).uniq.size
  end
  def test_find_recursive_shallow
    @cm.ruby <<-RUBY
      module Baz; end
      module Foo
        module Bar
          module Baz; end
        end
      end
      module Bar
        module Baz
        end
      end
      module Bar::Baz
        def blah; end
      end
    RUBY
    these = @cm.module('::Bar::Baz')
    assert_kind_of Array, these
    assert_equal 2, these.size
    assert_equal 2, these.map(&:object_id).uniq.size
  end
  def test_read_class_and_defns
    @cm.ruby <<-RUBY
      module Hi
        module Mom
          module I::Love
            class Cakes
              def foo; end
              def bar; end
            end
          end
        end
      end
    RUBY
    defns = @cm.module('::Hi::Mom::I::Love').klass('Cakes').defns
    assert_equal ['foo', 'bar'], defns.map(&:defn_name)
  end
  def test_set_defn_in_empty
    d1 = @cm.defn!('def foo; 1 + 1 end')
    d2 = @cm.defn('foo')
    assert_kind_of CodeMolester, d1
    assert_equal @cm.object_id, d1.object_id
    assert_kind_of CodeMolester, d2
    assert_equal d1.object_id, d2.object_id
  end
  def test_set_defn_in_strange
    @cm.ruby('1 + 1')
    e = assert_raises(RuntimeError) do
      @cm.defn!('def foo; 2 + 2; end')
    end
    assert_match(/Can't add a defn to a :call/i, e.message)
  end
  def test_get_defn_in_defn_node
    assert_equal nil, @cm.defn('foo'), "defn returns nil on empty codenode"
    @cm.ruby("def foo; 1+1 end")
    assert_equal nil, @cm.defn('foob'), "defn for nonexistant meth returns nil"
    get = @cm.defn('foo')
    assert_equal @cm.object_id, get.object_id, "defn on defn node returns self"
  end
  def test_get_defn_in_module
    @cm.ruby <<-RUBY
      module Foob ; def bar; end end
    RUBY
    get1 = @cm.defn('bar')
    get2 = @cm.module('Foob').defn('bar')
    get3 = @cm.defn('barz')
    assert_equal 'bar', get1.defn_name
    assert_equal get2.defn_name, get1.defn_name
    assert_equal get1.object_id, get2.object_id
    assert_equal nil, get3
  end
  def test_get_defn_in_class
    @cm.ruby <<-RUBY
      module Bliff
        class Blaff
          def fiz; end
        end
      end
    RUBY
    got = @cm.module('Bliff').klass('Blaff').defn('fiz')
    assert_kind_of CodeMolester, got
    assert_equal 'fiz', got.defn_name
  end
  def test_add_klass_in_empty
    foo = @cm.klass!('Foo')
    assert_kind_of CodeMolester, foo
    assert_equal @cm.object_id, foo.object_id
    assert_equal "class Foo\nend", foo.ruby
  end
  def test_add_klass_in_strange
    @cm.ruby('def foo; end')
    e = assert_raises(RuntimeError) do
      @cm.klass!('Foo')
    end
    assert_match(/don't know how to add class to :defn/i, e.message)
  end
  def test_add_module_when_module_is_node
    @cm.ruby("module Foo; end")
    mod = @cm.module!('Foo')
    assert_kind_of CodeMolester, mod
    assert_equal @cm.object_id, mod.object_id
  end
  def test_add_module_when_module_is_already_on_first_level
    @cm.ruby("module Foo; end; module Bar; end")
    mod = @cm.module!('Bar')
    assert_kind_of CodeMolester, mod
    assert mod.object_id != @cm.object_id
  end
  def test_add_module_when_module_is_one_level_down_WOZ1
    @cm.ruby("module Foo; module Bar; end; module Baz; end; end")
    mod1 = @cm.module('Baz')
    assert_kind_of CodeMolester, mod1
    mod2 = @cm.module!('Baz')
    assert_equal mod1.object_id, mod2.object_id
  end
  def test_add_module_when_module_is_two_levels_down_WOZ2
    @cm.ruby("module Foo; module Bar; end; module Baz; module Biff; end; end; end")
    mod1 = @cm.module('Biff')
    assert_kind_of CodeMolester, mod1
    mod2 = @cm.module!('Biff')
    assert_kind_of CodeMolester, mod2
    assert mod2.object_id != mod1.object_id
  end
  def test_add_module_to_inside_class
    @cm.ruby('module Foo::Bar; class Baz; end end')
    mod1 = @cm.module('::Foo::Bar').klass('Baz').module!('Biff')
    assert_kind_of CodeMolester, mod1
    mod2 = @cm.module('::Foo::Bar::Baz::Biff')
    assert_kind_of CodeMolester, mod2
    assert_equal 'Biff', mod2.module_name_local
  end
  def test_create_tree_and_copy_paste_method_definition
    @cm.ruby <<-RUBY
      def kizzme
        1 + 1
      end
    RUBY
    @cm2 = CodeMolester.new
    @cm2.module!('Foo').module!('Bar').klass!('Baz').defn!(
      @cm.defn('kizzme').ruby
    )
  end
end
