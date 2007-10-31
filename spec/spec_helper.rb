begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "../../lib"))
require 'giston'

$fixtures_dir = File.expand_path(File.dirname(__FILE__) + '/fixtures/')
$config = File.join($fixtures_dir, '.giston')
$somediff = File.join($fixtures_dir, 'some.diff')
$svninfo = File.join($fixtures_dir, 'svninfo')
