require File.dirname(__FILE__) + '/../integration_helper'

describe 'Adding a mirror in a clean repository' do

  before do
    FileUtils.rm_rf(TMP_PATH)
    FileUtils.mkdir_p(TMP_PATH)
  end

  describe 'from a git repository' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')
    end

    it 'should add the files and commit' do
      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir}")
      end

      file_name = 'skit1/layouts/layout.liquid'
      assert_no_diff("#{FIXTURE_PATH}/skit1/layouts/layout.liquid", "#{@repository_dir}/skit1/layouts/layout.liquid")

      output = run_command('git log --pretty=oneline').split("\n")
      output.length.should == 2
      output[0].should =~ /Braid: Add mirror 'skit1' at '[0-9a-f]{7}'/
    end

    it 'should create .braids.json and add the mirror to it' do
      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir}")
      end

      braids = YAML::load_file("#{@repository_dir}/.braids.json")
      braids['skit1']['squashed'].should == true
      braids['skit1']['url'].should == @vendor_repository_dir
      braids['skit1']['revision'].should_not be_nil
      braids['skit1']['branch'].should == 'master'
    end
  end
end
