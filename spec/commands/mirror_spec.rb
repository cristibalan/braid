require File.dirname(__FILE__) + '/../spec_helper.rb'

module GistonCommandsMirrorHelper
end

describe "Giston::Commands::Mirror" do
  include GistonCommandsMirrorHelper

  before(:each) do
    @config = mock("config")

    @mirror = Giston::Commands::Mirror.new("config" => @config)
    @mirror.stub!(:msg)

    @init = mock("init")
    Giston::Commands::Init.stub!(:new).and_return(@init)
    @fetch = mock("fetch")
    Giston::Commands::Fetch.stub!(:new).and_return(@fetch)
  end

  it "should pass along parameters to init and fetch" do
    @init.should_receive(:run).with("remote", "dir", "rev")
    @config.should_receive(:get).with("remote", "dir", "rev").and_return({"dir" => "dir", "url" => "remote", "rev" => "rev"})
    @fetch.should_receive(:run).with("dir")

    @mirror.run("remote", "dir", "rev")
  end


end
