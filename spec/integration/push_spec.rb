require File.dirname(__FILE__) + '/../integration_helper'

describe 'Pushing to a mirror' do

  before do
    FileUtils.rm_rf(TMP_PATH)
    FileUtils.mkdir_p(TMP_PATH)
  end

  describe 'from a git repository' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')
      @file_name = 'layouts/layout.liquid'

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir}")
      end

      in_dir(@vendor_repository_dir) do
        run_command('git config receive.denyCurrentBranch ignore')
      end

      update_dir_from_fixture('shiny/skit1', 'skit1.1')
      in_dir(@repository_dir) do
        run_command('git add *')
        run_command('git commit -m "Make some changes to vendored files"')
      end
    end

    context 'with remote updtodate' do
      it 'should push changes successfully' do
        braid_output = nil
        in_dir(@repository_dir) do
          set_editor_message('Make some changes')
          braid_output = run_command("#{EDITOR_CMD_PREFIX} #{BRAID_BIN} push skit1")
        end
        braid_output.should =~ /Braid: Cloning mirror with local changes./
        braid_output.should =~ /Make some changes/
        braid_output.should =~ /Braid: Pushing changes to remote branch master./

        assert_no_diff("#{FIXTURE_PATH}/skit1.1/#{@file_name}", "#{@repository_dir}/skit1/#{@file_name}")
        assert_no_diff("#{FIXTURE_PATH}/skit1.1/#{@file_name}", "#{@vendor_repository_dir}/#{@file_name}")
      end

      it 'should push changes to specified branch successfully' do
        braid_output = nil
        in_dir(@repository_dir) do
          set_editor_message('Make some changes')
          braid_output = run_command("#{EDITOR_CMD_PREFIX} #{BRAID_BIN} push skit1 --branch MyBranch")
        end
        braid_output.should =~ /Braid: Cloning mirror with local changes./
        braid_output.should =~ /Make some changes/
        braid_output.should =~ /Braid: Pushing changes to remote branch MyBranch./

        assert_no_diff("#{FIXTURE_PATH}/skit1/#{@file_name}", "#{@vendor_repository_dir}/#{@file_name}")
        assert_no_diff("#{FIXTURE_PATH}/skit1.1/#{@file_name}", "#{@repository_dir}/skit1/#{@file_name}")

        in_dir(@vendor_repository_dir) do
          run_command('git checkout MyBranch 2>&1')
        end

        assert_no_diff("#{FIXTURE_PATH}/skit1.1/#{@file_name}", "#{@vendor_repository_dir}/#{@file_name}")
      end
    end

    context 'with remote having changes' do
      before do
        update_dir_from_fixture('skit1', 'skit1.1')
        update_dir_from_fixture('skit1', 'skit1.2')
        in_dir(@vendor_repository_dir) do
          run_command('git add *')
          run_command('git commit -m "Update vendored directory"')
        end
      end
      it 'should push changes successfully' do
        braid_output = nil
        in_dir(@repository_dir) do
          set_editor_message('Make some changes')
          braid_output = run_command("#{EDITOR_CMD_PREFIX} #{BRAID_BIN} push skit1")
        end
        braid_output.should =~ /Braid: Mirror is not up to date. Stopping./

        assert_no_diff("#{FIXTURE_PATH}/skit1.2/#{@file_name}", "#{TMP_PATH}/skit1/#{@file_name}")
      end
    end
  end
end
