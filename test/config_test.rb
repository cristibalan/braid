require File.dirname(__FILE__) + '/test_helper'

describe_shared "Braid::Config, in general" do
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

  it "should not get a mirror by name" do
    @config.get("path").should.be.nil
    lambda { @config.get!("path") }.should.raise(Braid::Config::MirrorDoesNotExist)
  end

  it "should add a mirror and its params" do
    @mirror = build_mirror
    @config.add(@mirror)
    @config.get("path").path.should.not.be.nil
  end
end

describe "Braid::Config, with one mirror" do
  it_should_behave_like "Braid::Config, in general"

  before(:each) do
    @mirror = build_mirror
    @config.add(@mirror)
  end

  it "should get the mirror by name" do
    @config.get("path").should == @mirror
    @config.get!("path").should == @mirror
  end

  it "should raise when trying to overwrite a mirror on add" do
    lambda { @config.add(@mirror) }.should.raise(Braid::Config::PathAlreadyInUse)
  end

  it "should remove the mirror" do
    @config.remove(@mirror)
    @config.get("path").should.be.nil
  end

  it "should update the mirror with new params" do
    @mirror.branch = "other"
    @config.update(@mirror)
    @config.get("path").attributes.should == { "branch" => "other" }
  end

  it "should raise when trying to update nonexistent mirror" do
    @mirror.instance_variable_set("@path", "other")
    lambda { @config.update(@mirror) }.should.raise(Braid::Config::MirrorDoesNotExist)
  end
end
