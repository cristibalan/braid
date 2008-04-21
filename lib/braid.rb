$:.unshift File.dirname(__FILE__)

begin
  require 'rubygems'
rescue
end

module Braid
  MIRROR_TYPES = %w[git svn]
  TRACK_BRANCH = "braid/track"
  CONFIG_FILE = ".braids"
end

require 'braid/version'
require 'braid/exceptions'

require 'braid/config'
require 'braid/operations'
require 'braid/commands'
