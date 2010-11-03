require File.expand_path('../helper.rb', __FILE__)
require 'tempfile'
require 'fileutils'

CodeMolester = Hipe::CodeMolester

class TestMolester < MiniTest::Unit::TestCase
  @@curr = 0
  def next_empty_tmpdir
    dir = "#{Dir.tmpdir}/molest-#{@@curr += 1}"
    File.directory?(dir) || FileUtils.mkdir(dir, :verbose => 1)
    Dir["#{dir}/*"].empty? || FileUtils.rm_rf("#{dir}/*", :verbose => 1)
    dir
  end
  def setup
    @cm = CodeMolester.new
  end
  def test_fail_when_file_not_exist
    dir = next_empty_tmpdir
    e = assert_raises Errno::ENOENT do
      @cm.file("#{dir}/not-exist")
    end
    assert_match /No such file or directory/, e.message
  end
  def test_create_file_when_not_exist
    dir = next_empty_tmpdir
    path = "#{dir}/make-this-file"
    refute File.exist?(path)
    @cm.file!(path)
    assert File.exist?(path)
  end
end
