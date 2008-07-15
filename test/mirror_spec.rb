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
    @mirror = build_mirror("revision" => 'a' * 40)
    @mirror.stubs(:base_revision).returns(@mirror.revision) # bypass rev_parse
  end

  def set_hashes(remote_hash, local_hash)
    git.expects(:rev_parse).with("#{@mirror.revision}:").returns(remote_hash)
    git.expects(:tree_hash).with(@mirror.path).returns(local_hash)
  end

  it "should return an empty string when the hashes match" do
    set_hashes('b' * 40, 'b' * 40)
    git.expects(:diff_tree).never
    @mirror.diff.should == ""
  end

  it "should generate a diff when the hashes do not match" do
    set_hashes('b' * 40, 'c' * 40)
    diff = "diff --git a/path b/path\n"
    git.expects(:diff_tree).with('b' * 40, 'c' * 40, @mirror.path).returns(diff)
    @mirror.diff.should == diff
  end
end

describe "Braid::Mirror#base_revision" do
  it "should be inferred when no revision is set" do
    @mirror = build_mirror
    @mirror.revision.should.be.nil
    @mirror.expects(:inferred_revision).returns('b' * 40)
    @mirror.send(:base_revision).should == 'b' * 40
  end

  it "should be the parsed hash for git mirrors" do
    @mirror = build_mirror("revision" => 'a' * 7)
    git.expects(:rev_parse).with('a' * 7).returns('a' * 40)
    @mirror.send(:base_revision).should == 'a' * 40
  end
end

describe "Braid::Mirror#inferred_revision" do
  it "should return the last commit before the most recent update" do
    @mirror = new_from_options("git://path")
    @mirror.expects(:list_revisions).times(2).returns(
      [[4, 'a' * 40], [2, 'b' * 40]],
      [[1, 'c' * 40], [3, 'd' * 40], [5, 'e' * 40]]
    )
    @mirror.send(:inferred_revision).should == 'd' * 40
  end
end
