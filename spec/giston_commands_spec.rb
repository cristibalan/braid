require File.dirname(__FILE__) + '/spec_helper.rb'

module CommandsSpecHelper
  def valid_attributes
    {
      "dir" => '1',
      "url" => 'svn://1',
      "rev" => 1,
    }
  end
  def valid_attributes_ary
    ["svn://1", "-r", "1", "1"]
  end
end

describe "Giston::Commands.extract_add_params" do
  before(:each) do
    @config = mock("config")
    @cmds = Giston::Commands
    @cmds.stub!(:msg)

    @svn = mock('svn')
    Giston::Svn.stub!(:new).and_return(@svn)
  end

  it "should default dir and rev when only url is passed" do
    @svn.stub!(:remote_revision).and_return("5")
    @cmds.extract_add_params("svn://1").should == ["svn://1", "1", "5"]
    @cmds.extract_add_params("svn://1", "2").should == ["svn://1", "2", "5"]
    @cmds.extract_add_params("svn://1", "-r", "3", "2").should == ["svn://1", "2", "3"]
    @cmds.extract_add_params("svn://1", "3", "2").should == "Bad params. See giston help for usage."
  end

end

describe "Giston::Commands.add" do
  include CommandsSpecHelper

  before(:each) do
    @config = mock("config")
    @cmds = Giston::Commands
    @cmds.stub!(:config).and_return(@config)
    @cmds.stub!(:msg)
  end

  it "should add new mirror to config and save it" do
    @config.should_receive(:add).with(*valid_attributes_ary.reject{|x| x == '-r'}).and_return(true)
    @config.should_receive(:write)
    @cmds.add(*valid_attributes_ary)
  end

  it "should not save config when adding existing mirror" do
    @config.should_receive(:add).with(*valid_attributes_ary.reject{|x| x == '-r'}).twice.and_return(true, false)
    @config.should_receive(:write).once

    @cmds.add(*valid_attributes_ary)
    @cmds.add(*valid_attributes_ary)
  end
end

describe "@cmds.remove" do
  include CommandsSpecHelper

  before(:each) do
    @config = mock("config")
    @cmds = Giston::Commands
    @cmds.stub!(:config).and_return(@config)
    @cmds.stub!(:msg)
  end

  it "should remove existing mirror from config and save it" do
    @config.should_receive(:remove).with("1").and_return(true)
    @config.should_receive(:write)
    @cmds.remove("1")
  end

  it "should not save config when removing inexisting mirror" do
    @config.should_receive(:remove).with("1").twice.and_return(true, false)
    @config.should_receive(:write).once

    @cmds.remove("1")
    @cmds.remove("1")
  end
end

describe "@cmds.update_one" do
  include CommandsSpecHelper

  before(:each) do
    @cmds = Giston::Commands

    @diff = File.expand_path(File.dirname(__FILE__) + '/fixtures/a.diff')
    @binaries = ["some.gif", "other.gif"]

    @config = mock('config', :get => valid_attributes)
    @cmds.stub!(:config).and_return(@config)
    @cmds.stub!(:msg)
    @config.stub!(:write)

    @svn = mock('svn')
    Giston::Svn.stub!(:new).and_return(@svn)

    @git = mock('git')
    #Giston::Git.stub!(:new).and_return(@git)
    @cmds.stub!("git").and_return(@git)

    @local = mock('local')
    Giston::Local.stub!(:new).and_return(@local)
  end

  it "should return if no new remote content" do
    @config.should_receive(:get).with("1").and_return(valid_attributes)
    @git.should_receive(:local_directory_exists?).with("1").and_return(true)
    @svn.should_receive(:remote_revision).and_return(1)

    @cmds.update_one("1")
  end

  it "should return if local changes exist" do
    @config.should_receive(:get).with("1").and_return(valid_attributes)
    @svn.should_receive(:remote_revision).and_return(2)
    @git.should_receive(:local_directory_exists?).with("1").and_return(true)
    @git.should_receive(:local_changes?).with("1").and_return(true)

    @cmds.update_one("1")
  end

  it "should create new mirror if local directory does not exist" do
    @config.should_receive(:get).with("1").and_return(valid_attributes)
    @svn.should_receive(:remote_revision).and_return(2)
    @git.should_receive(:local_directory_exists?).with("1").and_return(false)
    @svn.should_receive(:export).with("1", 2)

    @cmds.update_one("1")
  end

  it "should update mirror if local directory exists" do
    @config.should_receive(:get).with("1").and_return(valid_attributes)
    @svn.should_receive(:remote_revision).and_return(2)
    @git.should_receive(:local_directory_exists?).with("1").and_return(true)
    @git.should_receive(:local_changes?).with("1").and_return(false)

    @svn.should_receive(:diff_file).with(1, 2).and_return(@diff)
    @local.should_receive(:patch).with(@diff, "1").and_return(true)
    @local.should_receive(:extract_binaries_from_diff).with(@diff).and_return(@binaries)
    @svn.should_receive(:cat).with("some.gif", 2, "1").and_return(true)
    @svn.should_receive(:cat).with("other.gif", 2, "1").and_return(true)

    @cmds.update_one("1")
  end

end

describe "@cmds.update" do
  include CommandsSpecHelper

  before(:each) do
    @cmds = Giston::Commands
    @config = mock('config')

    @cmds.stub!(:config).and_return(@config)
    @cmds.stub!(:msg)
  end

  it "should update given mirrors with update_one for the ones that exist" do

    @config.should_receive(:get).and_return(valid_attributes, nil)
    @cmds.should_receive(:update_one)
    @cmds.stub!(:update_one)

    @cmds.update(%w(1 2))
  end

  it "should update all mirrors with update_one" do
    @config.should_receive(:mirrors).and_return([valid_attributes])

    @cmds.should_receive(:update_one)
    @cmds.stub!(:update_one)

    @cmds.update
  end

end
