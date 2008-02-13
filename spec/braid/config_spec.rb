require File.dirname(__FILE__) + '/../spec_helper.rb'

describe Braid::Config, ".options_to_mirror" do

  before(:each) do
    @config = Braid::Config
  end

  it "should default branch to master" do
    name, params = @config.options_to_mirror("svn://path")

    params["branch"].should == "master"
  end

  it "should default type to svn, from protocol" do
    name, params = @config.options_to_mirror("svn://path")

    params["type"].should == "svn"
  end

  it "should default type to svn, if path ends in /trunk" do
    name, params = @config.options_to_mirror("http://path/trunk")

    params["type"].should == "svn"
  end

  it "should default type to git, from protocol" do
    name, params = @config.options_to_mirror("git://path")

    params["type"].should == "git"
  end

  it "should default type to git, if path ends in .git" do
    name, params = @config.options_to_mirror("http://path/trunk")

    params["type"].should == "svn"
  end

  it "should default mirror to last path part" do
    name, params = @config.options_to_mirror("http://path")

    name.should == "path"
  end

  it "should default mirror to previous to last path part, if last path part is /trunk" do
    name, params = @config.options_to_mirror("http://path/trunk")

    name.should == "path"
  end

  it "should default mirror to last path part, ignoring trailing .git" do
    name, params = @config.options_to_mirror("http://path.git")

    name.should == "path"
  end

end

describe Braid::Config, "when empty" do
  db = "tmp.yml"
  before(:each) do
    @config = Braid::Config.new(db)
  end
  after(:each) do
    FileUtils.rm db
  end

  it "should add a mirror and its params" do
    @config.add "mirror", "remote" => "path"

    @config.get("mirror").should == {"remote" => "path"}
  end

end

describe Braid::Config, "with one mirror" do
  db = "tmp.yml"
  before(:each) do
    @config = Braid::Config.new(db)
    @config.add "mirror", "remote" => "path"
  end
  after(:each) do
    FileUtils.rm db
  end

  it "should get the mirror by name" do
    @config.get("mirror").should == {"remote" => "path"}
  end

  it "should get the mirror by remote" do
    @config.get_by_remote("path").should == ["mirror", {"remote" => "path"}]
  end


  it "should raise when overwriting a mirror on add" do
    lambda { @config.add "mirror", "remote" => "other"}.should raise_error
  end

  it "should remove the mirror" do
    @config.remove("mirror")

    @config.get("mirror").should be_nil
  end

  it "should update the mirror with new params" do
    @config.update("mirror", "branch" => "other")

    @config.get("mirror").should == {"remote" => "path", "branch" => "other"}
  end

  it "should replace the mirror with the new params" do
    @config.replace("mirror", "branch" => "other")

    @config.get("mirror").should == {"branch" => "other"}
  end

  it "should raise when trying to update non existent mirror" do
    lambda { @config.update "N/A", {}}.should raise_error
  end

  it "should raise when trying to replace non existent mirror" do
    lambda { @config.replace "N/A", {}}.should raise_error
  end

end
