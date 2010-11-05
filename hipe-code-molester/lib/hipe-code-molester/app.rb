require 'rubygems' # wayne seguine told me personally that this is ok in framework code
require 'hipe-code-molester'
require 'hipe-tinyscript/core'

class Hipe::CodeMolester
  class MyCommand < Hipe::Tinyscript::Command
    def error type, str
      out colorize('error: ', :red) << str
      return type
    end
  end
  class App < Hipe::Tinyscript::App
    def version
      Hipe::CodeMolester::VERSION
    end
    description "just a sandbox testing ground to play with zenspider stuff"
    commands MyCommand
  end
end

Dir[File.dirname(__FILE__)+'/commands/*.rb'].each do |file|
  require file
end
