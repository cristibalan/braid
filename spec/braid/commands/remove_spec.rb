require File.dirname(__FILE__) + '/../../spec_helper.rb'

describe "Braid::Commands::Remove" do
  before(:each) do
    @config = stub_everything
    @cli = stub_everything
    @remove = Braid::Commands::Remove.new("config" => @config, "cli" => @cli)
    @remove.stub!(:msg)
  end

  it "should remove metadata from config" do
    @config.should_receive(:remove).with("mirror")

    @remove.run("mirror")
  end

end
