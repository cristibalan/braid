require File.dirname(__FILE__) + '/spec_helper.rb'

describe "Giston::CommandLine" do

  it "should dispatch commands correctly" do
    @cmds = Giston::Commands
    @cl = Giston::CommandLine
    @cl.stub!("msg")

    @cmds.should_receive("update").with(no_args())
    @cl.run("update")

    @cmds.should_receive("update").with("one")
    @cl.run(%w(update one))

    @cmds.should_receive("add")
    @cl.run(%w(add))

    @cmds.should_receive("remove")
    @cl.run(%w(remove))

    @cl.should_receive("msg").with("giston 0.1.0")
    @cl.run(%w(--version))

    @cl.should_receive("help").twice.with(no_args())
    @cl.run(%w(help))
    @cl.run(%w(blah))
  end
end
