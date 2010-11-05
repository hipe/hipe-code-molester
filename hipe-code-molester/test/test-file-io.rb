require File.dirname(__FILE__) + '/helper.rb'

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
  def test_comments_zoo
    orig_file = File.dirname(__FILE__) + '/fixtures/example-1.rb'
    orig_contents = File.read(orig_file)
    @cm.file(orig_file)
    unparsed_contents = @cm.ruby
    have = unparsed_contents.scan(/^ *# (\d+)\)/).map{ |x| x.first }
    need = %w(1 2 3 4 5 6 8 9 10) # not seven or eleven
    missing = need - have
    extra   = have - need
    assert_equal 0, missing.size, "these comment lines should have been parsed"
    assert_equal 0, extra.size, "these comments lines should not have been parsed"
  end
end
