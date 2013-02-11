require File.dirname(__FILE__) + '/test_helper'

describe "Braid::Config, when empty" do
  before(:each) do
    @config = Braid::Config.new("tmp.yml")
  end

  after(:each) do
    FileUtils.rm("tmp.yml") rescue nil
  end

  it "should not get a mirror by name" do
    @config.get("path").should be_nil
    lambda { @config.get!("path") }.should raise_error(Braid::Config::MirrorDoesNotExist)
  end

  it "should add a mirror and its params" do
    @mirror = build_mirror
    @config.add(@mirror)
    @config.get("path").path.should_not be_nil
  end
end

describe "Braid::Config, with one mirror" do
  before(:each) do
    @config = Braid::Config.new("tmp.yml")
    @mirror = build_mirror
    @config.add(@mirror)
  end

  after(:each) do
    FileUtils.rm("tmp.yml") rescue nil
  end

  it "should get the mirror by name" do
    @config.get("path").should == @mirror
    @config.get!("path").should == @mirror
  end

  it "should raise when trying to overwrite a mirror on add" do
    lambda { @config.add(@mirror) }.should raise_error(Braid::Config::PathAlreadyInUse)
  end

  it "should remove the mirror" do
    @config.remove(@mirror)
    @config.get("path").should be_nil
  end

  it "should update the mirror with new params" do
    @mirror.branch = "other"
    @config.update(@mirror)
    @config.get("path").attributes.should == {"branch" => "other"}
  end

  it "should raise when trying to update nonexistent mirror" do
    @mirror.instance_variable_set("@path", "other")
    lambda { @config.update(@mirror) }.should raise_error(Braid::Config::MirrorDoesNotExist)
  end
end
