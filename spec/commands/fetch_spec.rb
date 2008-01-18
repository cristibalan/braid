require File.dirname(__FILE__) + '/../spec_helper.rb'

module GistonCommandsFetchHelper
  def valid_mirror_hash
    {"dir" => "local/dir", "url" => "svn://remote/path", "rev" => "HEAD"}
  end
end

describe "Giston::Commands::Fetch" do
  include GistonCommandsFetchHelper

  before(:each) do
    @config = mock("config")
    @config.stub!(:write)
    @svn = mock("svn")
    @fetch = Giston::Commands::Fetch.new("config" => @config, "svn" => @svn)
    @fetch.stub!(:msg)
  end

  it "should export the mirror from the remote server and update the config" do
    @config.should_receive(:get).with("local/dir").and_return({"dir" => "local/dir", "url" => "svn://remote/path", "rev" => "HEAD"})
    @svn.should_receive(:export).with({"dir" => "local/dir", "url" => "svn://remote/path", "rev" => "HEAD"}).and_return("4")
    @config.should_receive(:update).with("local/dir", {"dir" => "local/dir", "url" => "svn://remote/path", "rev" => "4"})

    @fetch.run("local/dir")
  end

end
