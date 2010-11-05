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
end
