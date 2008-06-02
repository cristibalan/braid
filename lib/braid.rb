$:.unshift dir = File.dirname(__FILE__)

begin
  require 'rubygems'
rescue LoadError
end

require 'open4'
require 'yaml'
require 'yaml/store'

module Braid
  MIRROR_TYPES = %w[git svn]
  CONFIG_FILE = ".braids"
  REQUIRED_GIT_VERSION = "1.5.4.5"
  REQUIRED_GIT_SVN_VERSION = "1.5.4.5"
end

require 'braid/version'
require 'braid/exceptions'

require 'braid/config'
require 'braid/operations'

require 'braid/command'
Dir["#{dir}/braid/commands/*"].each do |file|
  require file
end
