require File.dirname(__FILE__) + '/../../spec_helper.rb'

module BraidCommandsUpdateHelper
end

describe "Braid::Commands::Update with no parameters" do
  include BraidCommandsUpdateHelper

  before(:each) do
    @config = mock("config")
    @update = Braid::Commands::Update.new("config" => @config)
    @update.stub!(:msg)
  end

  it "should update all mirrors" do
    @config.should_receive(:mirrors).and_return([{"dir" => "dir1", "url" => "remote1", "rev" => "4"}, {"dir" => "dir2", "url" => "remote2", "rev" => "13"}])
    @update.should_receive(:update_one).with("dir1")
    @update.should_receive(:update_one).with("dir2")

    @update.run
  end

end

describe "Braid::Commands::Update with parameters" do
  include BraidCommandsUpdateHelper

  before(:each) do
    @config = mock("config")
    @svn = mock("svn")
    @git = mock("git")
    @local = mock("local")
    @update = Braid::Commands::Update.new("config" => @config, "svn" => @svn, "git" => @git, "local" => @local)
    @update.stub!(:msg)
  end

  it "should default requested revision to remote revision" do
    @config.should_receive(:get).with("local/dir").and_return({"dir" => "local/dir", "url" => "remote/path", "rev" => "13"})
    @svn.should_receive(:remote_revision).and_return("4")

    lambda { @update.run("local/dir") }.should raise_error(Braid::Commands::LocalRevisionIsHigherThanRequestedRevision)
  end

  it "should raise if the local revision is higher than the requested revision" do
    @config.should_receive(:get).with("local/dir").and_return({"dir" => "local/dir", "url" => "remote/path", "rev" => "13"})
    @svn.should_receive(:remote_revision).and_return("4")

    lambda { @update.run("local/dir", "4") }.should raise_error(Braid::Commands::LocalRevisionIsHigherThanRequestedRevision)
  end

  it "should raise if the local revision is equal to the requested revision" do
    @config.should_receive(:get).with("local/dir").and_return({"dir" => "local/dir", "url" => "remote/path", "rev" => "13"})
    @svn.should_receive(:remote_revision).and_return("13")

    lambda { @update.run("local/dir", "13") }.should raise_error(Braid::Commands::MirrorAlreadyUpToDate)
  end

  it "should raise if the requested revision is higher than the remote revision" do
    @config.should_receive(:get).with("local/dir").and_return({"dir" => "local/dir", "url" => "remote/path", "rev" => "13"})
    @svn.should_receive(:remote_revision).and_return("13")

    lambda { @update.run("local/dir", "40") }.should raise_error(Braid::Commands::RequestedRevisionIsHigherThanRemoteRevision)
  end

  it "should raise if local git directory has changes" do
    @config.should_receive(:get).with("local/dir").and_return({"dir" => "local/dir", "url" => "remote/path", "rev" => "4"})
    @svn.should_receive(:remote_revision).and_return("13")
    @git.should_receive(:local_changes?).with("local/dir").and_return(true)

    lambda { @update.run("local/dir", "13") }.should raise_error(Braid::Git::LocalRepositoryHasUncommitedChanges)
  end

end

describe "Braid::Commands::Update with favorable conditions" do
  include BraidCommandsUpdateHelper

  before(:each) do
    @config = mock("config")
    @svn = mock("svn")
    @git = mock("git")
    @local = mock("local")
    @update = Braid::Commands::Update.new("config" => @config, "svn" => @svn, "git" => @git, "local" => @local)
    @update.stub!(:msg)

    @config.stub!(:get).and_return({"dir" => "local/dir", "url" => "remote/path", "rev" => "4"})
    @svn.stub!(:remote_revision).and_return("40")
    @git.stub!(:local_changes?).and_return(false)
  end

  it "should fetch and apply changes" do
    @svn.should_receive(:diff_file).with("remote/path", "4", "13").and_return("somefile.diff")
    @local.should_receive(:patch).with("somefile.diff", "local/dir")

    @local.should_receive(:extract_binaries_from_diff).with("somefile.diff").and_return(["some.gif", "other.gif"])
    @svn.should_receive(:cat).with("remote/path", "some.gif", "13", "local/dir")
    @svn.should_receive(:cat).with("remote/path", "other.gif", "13", "local/dir")

    @config.should_receive(:update).with("local/dir", {"dir" => "local/dir", "url" => "remote/path", "rev" => "13"})

    @update.run("local/dir", "13")
  end

end
