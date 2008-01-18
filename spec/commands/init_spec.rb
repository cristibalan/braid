require File.dirname(__FILE__) + '/../spec_helper.rb'

module GistonCommandsInitHelper
end

describe "Giston::Commands::Init" do
  include GistonCommandsInitHelper

  before(:each) do
    @config = mock("config")
    @svn = mock("svn")
    @init = Giston::Commands::Init.new("config" => @config, "svn" => @svn)
    @init.stub!(:msg)
  end

  it "should add the mirror from remote, mirror and revision" do
    @config.should_receive(:add).with({"dir" => "local/dir", "url" => "svn://remote/path", "rev" => "4"}).and_return(true)

    @init.run("svn://remote/path", "local/dir", "4")
  end

  it "should default revision to HEAD" do
    @svn.should_receive(:remote_revision).with("svn://remote/path").and_return("4")
    @config.should_receive(:add).with({"dir" => "local/dir", "url" => "svn://remote/path", "rev" => "4"}).and_return(true)

    @init.run("svn://remote/path", "local/dir")
  end

  it "should default mirror to last part of remote" do
    @svn.should_receive(:remote_revision).with("svn://remote/path").and_return("4")
    @config.should_receive(:add).with({"dir" => "path", "url" => "svn://remote/path", "rev" => "4"}).and_return(true)

    @init.run("svn://remote/path")
  end

  it "should default mirror to previous to last part of remote if the last one is /trunk" do
    @svn.should_receive(:remote_revision).with("svn://remote/path/trunk").and_return("4")
    @config.should_receive(:add).with({"dir" => "path", "url" => "svn://remote/path/trunk", "rev" => "4"}).and_return(true)

    @init.run("svn://remote/path/trunk")
  end

end
