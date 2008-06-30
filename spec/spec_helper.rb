require 'test/unit'

begin
  require 'rubygems'
  require 'spec'
  require 'mocha'
rescue LoadError
  puts <<-EOS
To run the specs you must install the rspec and mocha gems:
  . gem install rspec
  . gem install mocha
  EOS
  exit(1)
end

begin
  require 'ruby-debug'
rescue LoadError
end

Spec::Runner.configuration.mock_with :mocha

require File.dirname(__FILE__) + '/../lib/braid'
