$:.unshift File.dirname(__FILE__)

module Braid
  VERSION = "0.5"

  CONFIG_FILE = ".braids"
  REQUIRED_GIT_VERSION = "1.6"

  def self.verbose; @verbose || false; end
  def self.verbose=(new_value); @verbose = !!new_value; end

  def self.use_local_cache; [nil, "true", "1"].include?(ENV["BRAID_USE_LOCAL_CACHE"]); end
  def self.local_cache_dir; File.expand_path(ENV["BRAID_LOCAL_CACHE_DIR"] || "#{ENV["HOME"]}/.braid/cache"); end

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
