require File.dirname(__FILE__) + '/spec_helper'

describe "Braid::Mirror.new_from_options" do
  def new_from_options(url, options = {})
    @mirror = Braid::Mirror.new_from_options(url, options)
  end

  it "should default branch to master" do
    new_from_options("git://path")
    @mirror.branch.should == "master"
  end

  it "should default type to git, from protocol" do
    new_from_options("git://path")
    @mirror.type.should == "git"
  end

  it "should default type to git, if path ends in .git" do
    new_from_options("http://path.git")
    @mirror.type.should == "git"
  end

  it "should default type to svn, from protocol" do
    new_from_options("svn://path")
    @mirror.type.should == "svn"
  end

  it "should default type to svn, if path ends in /trunk" do
    new_from_options("http://path/trunk")
    @mirror.type.should == "svn"
  end

  it "should raise if no type can be guessed" do
    lambda { new_from_options("http://path") }.should raise_error(Braid::Mirror::CannotGuessType)
  end

  it "should default mirror to previous to last path part, if last path part is /trunk" do
    new_from_options("http://path/trunk")
    @mirror.path.should == "path"
  end

  it "should default mirror to last path part, ignoring trailing .git" do
    new_from_options("http://path.git")
    @mirror.path.should == "path"
  end
end

describe "Braid::Mirror#local_changes?" do
  before(:each) do
    @mirror = Braid::Mirror.new_from_options("git://path")
    Braid::Operations::Git.any_instance.expects(:rev_parse)
  end

  it "should return true when the diff is not empty" do
    Braid::Operations::Git.any_instance.expects(:diff_tree).returns("diff --git a/path b/path\n")
    @mirror.local_changes?.should be_true
  end

  it "should return false when the diff is empty" do
    Braid::Operations::Git.any_instance.expects(:diff_tree).returns("")
    @mirror.local_changes?.should be_false
  end
end
