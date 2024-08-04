require_relative '../lib/braid/check_gem'
require 'rubygems'
require 'rspec'
require 'mocha/api'

unless ENV['BRAID_USE_SORBET_RUNTIME']
  ENV['BRAID_USE_SORBET_RUNTIME'] = '1'
end

require File.dirname(__FILE__) + '/../lib/braid'

def new_from_options(url, options = Braid::Mirror::Options.new)
  @mirror = Braid::Mirror.new_from_options(url, options)
end

def build_mirror(options = {})
  Braid::Mirror.new('path', options)
end

include Braid::Operations::VersionControl

RSpec.configure do |config|
  config.mock_with :mocha
end
