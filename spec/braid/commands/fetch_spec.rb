require File.dirname(__FILE__) + '/../../spec_helper.rb'

module BraidCommandsFetchHelper
  def valid_mirror_hash
    {"dir" => "local/dir", "url" => "svn://remote/path", "rev" => "HEAD"}
  end
end

describe "Braid::Commands::Fetch" do
  include BraidCommandsFetchHelper

  before(:each) do
    @config = mock("config")
    @config.stub!(:write)
    @svn = mock("svn")
    @fetch = Braid::Commands::Fetch.new("config" => @config, "svn" => @svn)
    @fetch.stub!(:msg)
  end

  it "should export the mirror from the remote server and update the config" do
    @config.should_receive(:get).with("local/dir").and_return({"dir" => "local/dir", "url" => "svn://remote/path", "rev" => "4"})
    @svn.should_receive(:export).with("svn://remote/path", "4", "local/dir")
    @config.should_receive(:update).with("local/dir", {"dir" => "local/dir", "url" => "svn://remote/path", "rev" => "4"})

    @fetch.run("local/dir")
  end

end
