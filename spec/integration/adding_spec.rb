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

      assert_no_diff("#{FIXTURE_PATH}/skit1/layouts/layout.liquid", "#{@repository_dir}/skit1/layouts/layout.liquid")

      output = run_command('git log --pretty=oneline').split("\n")
      expect(output.length).to eq(2)
      expect(output[0]).to match(/Braid: Add mirror 'skit1' at '[0-9a-f]{7}'/)
    end

    it 'should create .braids.json and add the mirror to it' do
      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir}")
      end

      braids = YAML::load_file("#{@repository_dir}/.braids.json")
      expect(braids['skit1']['url']).to eq(@vendor_repository_dir)
      expect(braids['skit1']['revision']).not_to be_nil
      expect(braids['skit1']['branch']).to eq('master')
    end
  end
end
