require 'rubygems' # wayne sequine told me this is ok in application code not library code --
                   # a) the point is moot in 1.9.2 b) this is for running it in 1.8.7

cm_core = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(cm_core) unless $LOAD_PATH.include?(cm_core)

if false
  require 'ruby-debug'
  $stdout.puts(Hipe::Tinyscript::Colorize.colorize(
    "ruby-debug loaded (don't commit)", :bright, :blink, :red
  ))
end

begin
  require 'hipe-tinyscript/core'
rescue LoadError
  $LOAD_PATH.unshift File.expand_path('../../..', __FILE__) # @todo fixme!!!
  require 'hipe-tinyscript/core'
end
