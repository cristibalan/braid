$:.unshift dirname = File.dirname(__FILE__)
require 'braid/version'

module Braid
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

require dirname + '/core_ext'
require 'braid/operations'
require 'braid/mirror'
require 'braid/config'
require 'braid/command'
Dir[dirname + '/braid/commands/*'].each do |file|
  require file
end
