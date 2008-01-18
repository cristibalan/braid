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

$fixtures_dir = File.expand_path(File.dirname(__FILE__) + '/fixtures/')
$config = File.join($fixtures_dir, '.giston')
$somediff = File.join($fixtures_dir, 'some.diff')
$svninfo = File.join($fixtures_dir, 'svninfo')
