require File.dirname(__FILE__) + '/integration_helper'

describe 'Removing a mirror' do
  before do
    FileUtils.rm_rf(TMP_PATH)
    FileUtils.mkdir_p(TMP_PATH)
    @repository_dir = create_git_repo_from_fixture('shiny')
    @vendor_repository_dir = create_git_repo_from_fixture('skit1')
  end

  describe 'braided directly in' do
    before do
      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir}")

        # Next line ensure the remote still exists
        run_command("#{BRAID_BIN} setup skit1")
      end
    end

    it 'should remove the files and the remote' do

      assert_no_diff("#{FIXTURE_PATH}/skit1/layouts/layout.liquid", "#{@repository_dir}/skit1/layouts/layout.liquid")

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} remove skit1")
      end

      expect(File.exist?("#{@repository_dir}/skit1)")).to eq(false)

      braids = YAML::load_file("#{@repository_dir}/.braids.json")
      expect(braids['skit1']).to be_nil

      expect(`#{BRAID_BIN} remote | grep skit1`).to eq('')
    end
  end

  describe 'braiding a subdirectory in' do
    before do
      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir} --path layouts")
      end
    end

    it 'should remove the files and the remote' do

      assert_no_diff("#{FIXTURE_PATH}/skit1/layouts/layout.liquid", "#{@repository_dir}/skit1/layout.liquid")

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} remove skit1")
      end

      expect(File.exist?("#{@repository_dir}/skit1)")).to eq(false)

      braids = YAML::load_file("#{@repository_dir}/.braids.json")
      expect(braids['skit1']).to be_nil
    end
  end
end
