require File.dirname(__FILE__) + '/spec_helper.rb'

describe "Braid::Operations::Mirror#find_remote" do
  include Braid::Operations::Mirror

  before(:each) do
    File.should_receive(:readlines).and_return(["[remote \"braid/git/one\"]\n", "[svn-remote \"braid/git/two\"]\n"])
  end

  it "should return true for existing git remotes" do
    find_remote("braid/git/one").should == true
  end

  it "should return true for existing svn remotes" do
    find_remote("braid/git/two").should == true
  end

  it "should return false for nonexistent remotes" do
    find_remote("N/A").should == false
  end
end

describe Braid::Operations::Helpers, "extract_version" do
  it "should extract from git --version output" do
    self.stub!(:exec!).and_return([0, "git version 1.5.5.1.98.gf0ec4\n", ""])
    extract_version("git").should == "1.5.5.1.98.gf0ec4"
  end
  it "should extract from git svn --version output" do
    self.stub!(:exec!).and_return([0, "git-svn version 1.5.5.1.98.gf0ec4\n", ""])
    extract_version("git svn").should == "1.5.5.1.98.gf0ec4"
  end
end

describe Braid::Operations::Helpers, "verify_version against 1.5.4.5" do
  required_version = "1.5.4.5"
  should_pass      = %w(1.5.4.6 1.5.5 1.6 1.5.4.5.2 1.5.5.1.98.gf0ec4)
  should_not_pass  = %w(1.5.4.4 1.5.4 1.5.3 1.4.5.6)

  should_pass.each do |actual_version|
    it "should be true for #{actual_version}" do
      self.should_receive(:extract_version).with("some git executable").and_return(actual_version)
      verify_version("some git executable", "1.5.4.5").should == true
    end
  end

  should_not_pass.each do |actual_version|
    it "should be false for #{actual_version}" do
      self.should_receive(:extract_version).with("some git executable").and_return(actual_version)
      verify_version("some git executable", "1.5.4.5").should == false
    end
  end
end
