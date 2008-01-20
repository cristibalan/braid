begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  #gem 'rspec'
  require 'spec'
end

dir = File.dirname(__FILE__)
lib_path = File.expand_path("#{dir}/../lib")
$LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)

require 'giston'
