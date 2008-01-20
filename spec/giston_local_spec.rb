require File.dirname(__FILE__) + '/spec_helper.rb'

describe "Giston::Local" do
  before(:each) do
    @local = Giston::Local.new

    @local.stub!(:sys)
  end

  it "should apply given diff file" do
    @local.should_receive(:sys).with("patch -d somedir -p0 < some.diff")

    @local.patch("some.diff", "somedir")
  end

  it "should correctly extract binaries from diff file" do
    @local.should_receive(:sys).with('grep -e "Cannot display: file marked as a binary type." -B 2 some.diff | grep -e "Index: " | sed -e "s/Index: //"')

    @local.extract_binaries_from_diff("some.diff")
  end
end
