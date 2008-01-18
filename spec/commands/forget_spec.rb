require File.dirname(__FILE__) + '/../spec_helper.rb'

module GistonCommandsForgetHelper
end

describe "Giston::Commands::Forget" do
  include GistonCommandsForgetHelper

  before(:each) do
    @config = mock("config")

    @forget = Giston::Commands::Forget.new("config" => @config)
    @forget.stub!(:msg)
  end

  it "should pass along parameters to init and fetch" do
    @config.should_receive(:remove).with("local/dir")

    @forget.run("local/dir")
  end


end
