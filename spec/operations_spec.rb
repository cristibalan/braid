require File.dirname(__FILE__) + '/spec_helper'

describe "Braid::Operations::Git#remote_exists?" do
  include Braid::Operations::VersionControl

  before(:each) do
    File.expects(:readlines).returns(["[remote \"braid/git/one\"]\n", "[svn-remote \"braid/git/two\"]\n"])
  end

  it "should return true for existing git remotes" do
    git.remote_exists?("braid/git/one").should be_true
  end

  it "should return true for existing svn remotes" do
    git.remote_exists?("braid/git/two").should be_true
  end

  it "should return false for nonexistent remotes" do
    git.remote_exists?("N/A").should be_false
  end
end

describe "Braid::Operations::Git#rev_parse" do
  include Braid::Operations::VersionControl

  it "should return the full hash when a hash is found" do
    full_revision = 'a' * 40
    Braid::Operations::Git.any_instance.expects(:exec).returns([0, full_revision, ""])
    git.rev_parse('a' * 7).should == full_revision
  end

  it "should raise a revision error when the hash is not found" do
    ambiguous_revision = 'b' * 7
    Braid::Operations::Git.any_instance.expects(:exec).returns([1, ambiguous_revision, "fatal: ..."])
    lambda { git.rev_parse(ambiguous_revision) }.should raise_error(Braid::Operations::Git::UnknownRevision)
  end
end

describe "Braid::Operations::Git#version" do
  include Braid::Operations::VersionControl

  ACTUAL_VERSION = "1.5.5.1.98.gf0ec4"

  before(:each) do
    Braid::Operations::Git.any_instance.expects(:exec).returns([0, "git version #{ACTUAL_VERSION}\n", ""])
  end

  it "should extract from git --version output" do
    git.version.should == ACTUAL_VERSION
  end
end

describe "Braid::Operations::Git#require_version" do
  include Braid::Operations::VersionControl

  REQUIRED_VERSION = "1.5.4.5"
  PASS_VERSIONS = %w(1.5.4.6 1.5.5 1.6 1.5.4.5.2 1.5.5.1.98.gf0ec4)
  FAIL_VERSIONS  = %w(1.5.4.4 1.5.4 1.5.3 1.4.5.6)

  def set_version(str)
    Braid::Operations::Git.any_instance.expects(:exec).returns([0, "git version #{str}\n", ""])
  end

  it "should return true for higher revisions" do
    PASS_VERSIONS.each do |version|
      set_version(version)
      git.require_version(REQUIRED_VERSION).should be_true
    end
  end

  it "should return false for lower revisions" do
    FAIL_VERSIONS.each do |version|
      set_version(version)
      git.require_version(REQUIRED_VERSION).should be_false
    end
  end
end
