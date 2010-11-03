cm_core = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(cm_core) unless $LOAD_PATH.include?(cm_core)

require 'hipe-code-molester'
require 'minitest/autorun'
