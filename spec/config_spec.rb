require File.dirname(__FILE__) + '/spec_helper.rb'

describe "Braid::Config.options_to_mirror" do
  before(:each) do
    @config = Braid::Config
  end

  it "should default branch to master" do
    name, params = @config.options_to_mirror("git://path")
    params["branch"].should == "master"
  end

  it "should default type to git, from protocol" do
    name, params = @config.options_to_mirror("git://path")
    params["type"].should == "git"
  end

  it "should default type to git, if path ends in .git" do
    name, params = @config.options_to_mirror("http://path.git")
    params["type"].should == "git"
  end

  it "should default type to svn, from protocol" do
    name, params = @config.options_to_mirror("svn://path")
    params["type"].should == "svn"
  end

  it "should default type to svn, if path ends in /trunk" do
    name, params = @config.options_to_mirror("http://path/trunk")
    params["type"].should == "svn"
  end

  it "should raise if no type can be guessed" do
    lambda { @config.options_to_mirror("http://path") }.should raise_error(Braid::Config::CannotGuessMirrorType)
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

describe "Braid::Config, in general", :shared => true do
  db = "tmp.yml"

  before(:each) do
    @config = Braid::Config.new(db)
  end

  after(:each) do
    FileUtils.rm(db) rescue nil
  end
end

describe "Braid::Config, when empty" do
  it_should_behave_like "Braid::Config, in general"

  it "should add a mirror and its params" do
    @config.add("mirror", "remote" => "path")
    @config.get("mirror").should == { "remote" => "path" }
  end

  it "should not get a mirror by name" do
    @config.get("mirror").should be_nil
    lambda { @config.get!("mirror") }.should raise_error(Braid::Config::MirrorDoesNotExist)
  end
end

describe "Braid::Config, with one mirror" do
  it_should_behave_like "Braid::Config, in general"

  before(:each) do
    @mirror = { "remote" => "path" }
    @config.add("mirror", @mirror)
  end

  it "should get the mirror by name" do
    @config.get("mirror").should == @mirror
    @config.get!("mirror").should == @mirror
  end

  it "should get the mirror by remote" do
    @config.get_by_remote("path").should == ["mirror", @mirror]
  end

  it "should raise when overwriting a mirror on add" do
    lambda { @config.add "mirror", "remote" => "other" }.should raise_error(Braid::Config::MirrorNameAlreadyInUse)
  end

  it "should remove the mirror" do
    @config.remove("mirror")
    @config.get("mirror").should be_nil
  end

  it "should update the mirror with new params" do
    @config.update("mirror", "branch" => "other")
    @config.get("mirror").should == { "remote" => "path", "branch" => "other" }
  end

  it "should replace the mirror with the new params" do
    @config.replace("mirror", "branch" => "other")
    @config.get("mirror").should == { "branch" => "other" }
  end

  it "should raise when trying to update nonexistent mirror" do
    lambda { @config.update "N/A", {} }.should raise_error(Braid::Config::MirrorDoesNotExist)
  end

  it "should raise when trying to replace nonexistent mirror" do
    lambda { @config.replace "N/A", {} }.should raise_error(Braid::Config::MirrorDoesNotExist)
  end
end
