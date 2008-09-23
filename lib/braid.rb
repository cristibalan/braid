$:.unshift File.dirname(__FILE__)

module Braid
  VERSION = "0.4.10"

  CONFIG_FILE = ".braids"
  USE_LOCAL_CACHE = ENV["BRAID_USE_LOCAL_CACHE"] || true
  LOCAL_CACHE_DIR = ENV["BRAID_LOCAL_CACHE_DIR"] || "#{ENV["HOME"]}/.braid/cache/"
  REQUIRED_GIT_VERSION = "1.5.4.5"

  class BraidError < StandardError
    def message
      value = super
      value if value != self.class.name
    end
  end
end

require 'braid/operations'
require 'braid/mirror'
require 'braid/config'
require 'braid/command'
Dir[File.dirname(__FILE__) + '/braid/commands/*'].each do |file|
  require file
end
