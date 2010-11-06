# Hipe Code Molester

## Abstract

Creates *and alters* ruby files with a DSL on top of good zenspider gems.  Experiment in code generation applied to source files also edited by humans.

## Example

  add_these = CodeMolester.new.ruby <<-RUBY
		module Foo
		  def bar; 'bar' end
		  def baz; 'baz' end
	  end
  RUBY


	to_this = CodeMolester.new('your-code.rb')
	# contents of your-code.rb: 
	#   class Baz
	#     def biff; 'hi' end
  #   end
	#
	to_this.class('Baz').defn!(add_these.module('Foo').defn('bar')).write!
	
	# new contents of your-code.rb:
	# 
	#   class Baz
	#     def biff; 'hi' end
	#     def bar; 'bar' end
  #   end
	