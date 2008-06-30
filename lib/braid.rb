$:.unshift File.dirname(__FILE__)

begin
  require 'rubygems'
rescue LoadError
end

module Braid
  CONFIG_FILE = ".braids"
  REQUIRED_GIT_VERSION = "1.5.4.5"

  class BraidError < StandardError
  end
end

require 'braid/version'
require 'braid/operations'
require 'braid/mirror'
require 'braid/config'
require 'braid/command'
Dir[File.dirname(__FILE__) + '/braid/commands/*'].each do |file|
  require file
end
