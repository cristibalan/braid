require File.dirname(__FILE__) + '/../integration_helper'

describe "Adding a mirror in a clean repository" do

  before do
    FileUtils.rm_rf(TMP_PATH)
    FileUtils.mkdir_p(TMP_PATH)
  end


  describe "from a git repository" do
    before do
      @shiny = create_git_repo_from_fixture("shiny")
      @skit1 = create_git_repo_from_fixture("skit1")
    end

    it "should add the files and commit" do
      in_dir(@shiny) do
        `braid add --type git #{@skit1}`
      end

      file_name = "skit1/layouts/layout.liquid"
      output = `diff -U 3 #{File.join(FIXTURE_PATH, file_name)} #{File.join(TMP_PATH, "shiny", file_name)}`
      $?.should.be.success

      output = `git log --pretty=oneline`.split("\n")
      output.length.should == 2
      output[0].should =~ "Add mirror 'skit1/'"
    end
  end

  describe "from an svn repository" do
    before do
      @shiny = create_git_repo_from_fixture("shiny")
      @skit1 = create_svn_repo_from_fixture("skit1")
    end

    it "should add the files and commit" do
      in_dir(@shiny) do
        `braid add --type svn #{@skit1}`
      end

      file_name = "skit1/layouts/layout.liquid"
      output = `diff -U 3 #{File.join(FIXTURE_PATH, file_name)} #{File.join(TMP_PATH, "shiny", file_name)}`
      $?.should.be.success

      output = `git log --pretty=oneline`.split("\n")
      output.length.should == 2
      output[0].should =~ "Add mirror 'skit1/'"
    end
  end



end

