require File.dirname(__FILE__) + '/helper.rb'

class TestDefnMolestation < MiniTest::Unit::TestCase
  include MolesterTester, Hipe::Tinyscript::Stringy # unindent
  # no setup!
  def test_copy_alter_paste
    from = CodeMolester.new.ruby <<-RUBY
      module TheseMethods
        def foo_blah; 1 + 1 end
        def foo_bliz; end
      end
    RUBY
    to_file = File.join(next_empty_tmpdir, 'human-editable.rb')
    File.open(to_file, 'w') do |fh|
      fh.write <<-RUBY
        module MyModule
          class MyClass
            def my_meth; 'hi' end
          end
        end
      RUBY
    end
    # this should look like the readme
    to = CodeMolester.new.file(to_file)
    d = to.klass('MyModule::MyClass').defn!(from.module('TheseMethods').defn('foo_blah').ruby)
    want = unindent(<<-RUBY).chomp
    module MyModule
      class MyClass
        def my_meth
          "hi"
        end
        def foo_blah
          (1 + 1)
        end
      end
    end
    RUBY
    assert_equal want, to.ruby, "the generated code shouldhave the added method"
  end
end
