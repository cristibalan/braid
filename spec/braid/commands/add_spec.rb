require File.dirname(__FILE__) + '/../../spec_helper.rb'

describe "Braid::Commands::Add" do
  before(:each) do
    @config = stub_everything
    @cli = stub_everything
    @add = Braid::Commands::Add.new("config" => @config, "cli" => @cli)
    @add.stub!(:msg)
  end

  it "should save metadata to config" do
    @config.should_receive(:add_from_options).and_return(["mirror", {"remote" => "remote", "type" => "svn"}])

    @add.run("remote")
  end

end
