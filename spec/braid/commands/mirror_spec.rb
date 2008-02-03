require File.dirname(__FILE__) + '/../../spec_helper.rb'

module BraidCommandsMirrorHelper
end

describe "Braid::Commands::Mirror" do
  include BraidCommandsMirrorHelper

  before(:each) do
    @config = mock("config")
    @config2 = mock("config")

    @mirror = Braid::Commands::Mirror.new("config" => @config)
    @mirror.stub!(:msg)

    @init = mock("init")
    Braid::Commands::Init.stub!(:new).and_return(@init)
    @fetch = mock("fetch")
    Braid::Commands::Fetch.stub!(:new).and_return(@fetch)
  end

  it "should pass along parameters to init and fetch" do
    @init.should_receive(:run).with("remote", "dir", "4")
    @fetch.should_receive(:run).with("dir")

    @mirror.run("remote", "dir", "4")
  end

  it "should pass along parameters to init and fetch and grab mirror name from config if not passed" do
    @init.should_receive(:run).with("remote", nil, nil)
    Braid::Config.should_receive(:new).and_return(@config2)
    @config2.should_receive(:get_from_remote).with("remote").and_return({"dir" => "dir", "url" => "remote", "rev" => "4"})
    @fetch.should_receive(:run).with("dir")

    @mirror.run("remote")
  end


end
