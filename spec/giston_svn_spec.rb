require File.dirname(__FILE__) + '/spec_helper.rb'
require 'yaml'

describe "Giston::Svn" do
  before(:each) do
    @svn = Giston::Svn.new("svn://1")
    @info = YAML.load_file($svninfo)
    @diff = File.read($somediff)

    @svn.stub!(:info).and_return(@info)
    @svn.stub!(:sys)
  end

  it "should load svn info like output" do
    pending("i'm lazy")
  end

  it "should grab last commited from remote svn repository" do
    @svn.remote_revision.should == 2952
  end

  it "should should call svn to get diff" do
    @svn.should_receive(:sys).with("svn diff -r 1:2 svn://1")

    @svn.diff(1, 2)
  end

  it "should produce diff in a temporary file" do
    @svn.stub!(:diff).and_return(@diff)

    @svn.diff_file(1, 2).should match /\/gistonsvndiff/
  end

  it "should cat files from remote svn repository" do
    @svn.should_receive(:sys).with("svn cat -r 2 svn://1/img.gif > 1/img.gif")

    @svn.cat("img.gif", 2, "1")
  end

end
