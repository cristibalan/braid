require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "Braid::Git" do
  before(:each) do
    @git = Braid::Git.new

    @git.stub!(:sys)
  end

  it "should report no changes when git status reports no changes" do
    @git.stub!(:sys).and_return("")

    @git.local_changes?("dir").should == false
  end

  it "should report changes when git status reports changes" do
    @git.stub!(:sys).and_return("something")

    @git.local_changes?("dir").should == true
  end
end
