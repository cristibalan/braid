require File.dirname(__FILE__) + '/../integration_helper'

describe "Updating a mirror without conflicts" do

  before do
    FileUtils.rm_rf(TMP_PATH)
    FileUtils.mkdir_p(TMP_PATH)
  end

  describe "from a git repository" do
    before do
      @shiny = create_git_repo_from_fixture("shiny")
      @skit1 = create_git_repo_from_fixture("skit1")

      in_dir(@shiny) do
        `#{BRAID_BIN} add --type git #{@skit1}`
      end

      update_dir_from_fixture("skit1", "skit1.1")
      in_dir(@skit1) do
        `git add *`
        `git commit -m "change default color"`
      end

      update_dir_from_fixture("skit1", "skit1.2")
      in_dir(@skit1) do
        `git add *`
        `git commit -m "add a happy note"`
      end

    end

    it "should add the files and commit" do
      in_dir(@shiny) do
        `#{BRAID_BIN} update skit1`
      end

      file_name = "layouts/layout.liquid"
      output = `diff -U 3 #{File.join(FIXTURE_PATH, "skit1.2", file_name)} #{File.join(TMP_PATH, "shiny", "skit1", file_name)}`
      $?.should.be.success

      output = `git log --pretty=oneline`.split("\n")
      output.length.should == 3
      output[0].should =~ /Braid: Updated mirror 'skit1' to '[0-9a-f]{7}'/
    end

  end

  describe "from a svn repository" do
    before do
      @shiny = create_git_repo_from_fixture("shiny")
      @skit1 = create_svn_repo_from_fixture("skit1")
      @skit1_wc = File.join(TMP_PATH, "skit1_wc")

      in_dir(@shiny) do
        `#{BRAID_BIN} add --type svn #{@skit1}`
      end

      update_dir_from_fixture("skit1_wc", "skit1.1")
      in_dir(@skit1_wc) do
        `svn commit -m "change default color"`
      end

      update_dir_from_fixture("skit1_wc", "skit1.2")
      in_dir(@skit1_wc) do
        `svn commit -m "add a happy note"`
      end

    end

    it "should add the files and commit" do
      in_dir(@shiny) do
        `#{BRAID_BIN} update skit1`
      end

      file_name = "layouts/layout.liquid"
      output = `diff -U 3 #{File.join(FIXTURE_PATH, "skit1.2", file_name)} #{File.join(TMP_PATH, "shiny", "skit1", file_name)}`
      $?.should.be.success

      output = `git log --pretty=oneline`.split("\n")
      output.length.should == 3
      output[0].should =~ /Braid: Updated mirror 'skit1' to r3/
    end

  end

end
