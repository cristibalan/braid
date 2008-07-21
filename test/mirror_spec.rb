require File.dirname(__FILE__) + '/test_helper'

describe "Braid::Mirror.new_from_options" do
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
    lambda { new_from_options("http://path") }.should.raise(Braid::Mirror::CannotGuessType)
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

describe "Braid::Mirror#diff" do
  before(:each) do
    @mirror = new_from_options("git://path")
    git.stubs(:rev_parse)
    git.stubs(:tree_hash)
  end

  it "should return true when the diff is not empty" do
    git.expects(:diff_tree).returns("diff --git a/path b/path\n")
    @mirror.local_changes?.should == true
  end

  it "should return false when the diff is empty" do
    git.expects(:diff_tree).returns("")
    @mirror.local_changes?.should == false
  end
end

describe "Braid::Mirror#base_revision" do
  it "should be nil when no revision is set" do
    @mirror = Braid::Mirror.new("path")
    @mirror.revision.should.be.nil
    @mirror.send(:base_revision).should.be.nil
  end

  it "should be the parsed hash for git mirrors" do
    @mirror = Braid::Mirror.new("path", "revision" => ('a' * 7))
    git.expects(:rev_parse).returns('a' * 40)
    @mirror.send(:base_revision).should == 'a' * 40
  end
end
