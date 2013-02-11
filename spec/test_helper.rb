require 'rubygems'
require 'rspec'
require 'mocha/api'

require File.dirname(__FILE__) + '/../lib/braid'

def new_from_options(url, options = {})
  @mirror = Braid::Mirror.new_from_options(url, options)
end

def build_mirror(options = {})
  Braid::Mirror.new("path", options)
end

include Braid::Operations::VersionControl
