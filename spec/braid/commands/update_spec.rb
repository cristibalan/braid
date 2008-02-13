require File.dirname(__FILE__) + '/../../spec_helper.rb'

describe "Braid::Commands::Update" do
  before(:each) do
    @config = stub_everything
    @cli = stub_everything
    @update = Braid::Commands::Update.new("config" => @config, "cli" => @cli)
    @update.stub!(:msg)
  end

end
