require File.expand_path('../helper.rb', __FILE__)
require 'tempfile'
require 'fileutils'

CodeMolester = Hipe::CodeMolester

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

class TestFileMolestation < MiniTest::Unit::TestCase
  include MolesterTester
  def setup
    @cm = CodeMolester.new
  end
  def test_fail_when_file_not_exist
    dir = next_empty_tmpdir
    e = assert_raises Errno::ENOENT do
      @cm.file("#{dir}/not-exist")
    end
    assert_match(/No such file or directory/, e.message)
  end
  def test_create_file_when_not_exist
    dir = next_empty_tmpdir
    path = "#{dir}/make-this-file"
    refute File.exist?(path), 'path should not exist'
    @cm.file!(path)
    assert File.exist?(path), 'path should exist'
  end
end

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
    @cm.ruby(<<-RUBY)
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
    @cm.ruby(<<-RUBY)
      module Alpha; end
      module Beta;  end
      module Gamma; end
    RUBY
    found = @cm.module('Beta')
    assert_kind_of Hipe::CodeMolester, found
    assert found.object_id != @cm.object_id, "should not return self for this"
  end
  def test_find_two_among_several
    @cm.ruby(<<-RUBY)
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
    @cm.ruby(<<-RUBY)
      module Foo::Bar::Baz; end
    RUBY
    assert_nil nil, @cm.module('Foo')
  end
  def test_find_one_deep_simple
    @cm.ruby(<<-RUBY)
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
    @cm.ruby(<<-RUBY)
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

  end
end