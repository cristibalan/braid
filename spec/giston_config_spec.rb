require File.dirname(__FILE__) + '/spec_helper.rb'

module ConfigSpecHelper
  def valid_attributes
    {
      "dir" => '1',
      "url" => 'svn://1',
      "rev" => 1,
    }
  end
  def valid_attributes_ary
    ["svn://1",  "1", 1]
  end
end

describe "Giston::Config" do
  include ConfigSpecHelper

  it "should use default config file when none is passed" do
    g = Giston::Config.new
    g.config_file.should == '.giston'

    g = Giston::Config.new('blah')
    g.config_file.should == 'blah'
  end

  it "should check for existance of mirror by dir" do
    g = Giston::Config.new($config)
    g.read
    g.should have_item("local/mirror1")
  end

  it "should get mirror from dir" do
    g = Giston::Config.new($config)
    g.read
    g.get("local/mirror1")["url"] = "svn://remote/mirror1"
  end

  it "should get mirror from dir regardless of slashes" do
    g = Giston::Config.new($config)
    g.read
    g.get("local/mirror1/")["url"] = "svn://remote/mirror1"
  end

  it "should get actual mirror from mirror hash" do
    g = Giston::Config.new($config)
    g.read
    g.get({"dir" => "local/mirror1", "url" => "blah"})["url"] = "svn://remote/mirror1"
  end

  it "should check if mirror directory exists on disk" do
    File.should_receive(:exists?).with("path/local/mirror1").and_return(false)

    g = Giston::Config.new("path/blah")
    g.has_mirror_on_disk?("local/mirror1")
  end

  it "should add mirror to mirror list" do
    g = Giston::Config.new
    g.add(*valid_attributes_ary)
    g.should have_item("1")
  end

  it "should not add existing mirror to mirror list" do
    g = Giston::Config.new
    g.add(*valid_attributes_ary)
    g.add(*valid_attributes_ary).should == nil
  end

  it "should remove mirror given it's dir" do
    g = Giston::Config.new($config)
    g.read
    g.should have_item("local/mirror1")

    g.remove("local/mirror1")
    g.should_not have_item("local/mirror1")
  end

  it "should load mirrors from given config_file" do
    g = Giston::Config.new($config)
    g.read
    g.should have_item("local/mirror1")
  end

  it "should write mirrors to config_file" do
    g = Giston::Config.new($config + "2")
    g.mirrors.should be_empty
    g.mirrors << valid_attributes
    g.write

    g = Giston::Config.new($config + "2")
    g.read
    g.should have_item("1")
    File.delete($config + "2")
  end

  it "should reload mirrors form config_file" do
    g1 = Giston::Config.new($config + "2")
    g1.mirrors << valid_attributes

    g2 = Giston::Config.new($config + "2")
    g2.mirrors << valid_attributes.merge({"dir" => "2"})
    g2.write

    g1.should have_item("1")
    g1.reload
    g1.should_not have_item("1")
    g1.should have_item("2")

    File.delete($config + "2")
  end

end

