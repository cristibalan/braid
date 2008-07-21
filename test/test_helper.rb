require 'rubygems'
require 'test/spec'
require 'mocha'

require File.dirname(__FILE__) + '/../lib/braid'

def new_from_options(url, options = {})
  @mirror = Braid::Mirror.new_from_options(url, options)
end

def build_mirror
  Braid::Mirror.new("path", "url" => "url")
end

include Braid::Operations::VersionControl
