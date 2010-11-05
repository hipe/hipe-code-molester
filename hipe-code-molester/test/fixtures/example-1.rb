# 1) !/usr/bin/env ruby
# 2) require 'rubygems'; require 'ruby-debug'; puts "\e[1;5;33mruby-debug\e[0m"
class BaseClass;
  # 3) BC inner
end
# 4) comment2 for SomeMod
module SomeMod;
  # 5) NEVERSEE of someMod
  def blah
  end
end
# 6) comment for Child1 outer
class SomeMod::Child1 < BaseClass
  def blah
  end
end
# 8) comment for Child2 outer
class SomeMod::Child2 < BaseClass
  # 9) comment for Child2 outer
  def blah
  end
end
obj = Object.new
# 10) hi mom
def obj.blah; end
# 11) who hah