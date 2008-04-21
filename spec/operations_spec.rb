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
