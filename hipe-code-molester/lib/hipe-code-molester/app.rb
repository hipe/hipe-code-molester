require 'hipe-tinyscript/core'

module Hipe::CodeMolester
  class MyCommand < Hipe::Tinyscript::Command
    def error type, str
      out colorize('error: ', :red) << str
      return :type
    end
  end
  class App < Hipe::Tinyscript::App
    description "just a sandbox testing ground to play with zenspider stuff"
    commands MyCommand
  end
end

Dir[File.dirname(__FILE__)+'/commands/*.rb'].each do |file|
  require file
end
