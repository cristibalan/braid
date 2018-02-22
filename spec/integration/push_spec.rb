require File.dirname(__FILE__) + '/integration_helper'

describe 'Pushing to a mirror' do

  before do
    FileUtils.rm_rf(TMP_PATH)
    FileUtils.mkdir_p(TMP_PATH)
  end

  describe 'from a git repository' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny', :name => 'Some body', :email => 'somebody@example.com')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')
      @file_name = 'layouts/layout.liquid'

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir}")
      end

      in_dir(@vendor_repository_dir) do
        run_command('git config receive.denyCurrentBranch updateInstead')
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
        commit_message = 'Make some changes'
        in_dir(@repository_dir) do
          with_editor_message(commit_message) do
            braid_output = run_command("#{BRAID_BIN} push skit1")
          end
        end
        expect(braid_output).to match(/Braid: Cloning mirror with local changes./)
        expect(braid_output).to match(/Make some changes/)
        expect(braid_output).to match(/Braid: Pushing changes to remote branch master./)

        assert_no_diff("#{FIXTURE_PATH}/skit1.1/#{@file_name}", "#{@repository_dir}/skit1/#{@file_name}")
        assert_no_diff("#{FIXTURE_PATH}/skit1.1/#{@file_name}", "#{@vendor_repository_dir}/#{@file_name}")

        in_dir(@vendor_repository_dir) do
          run_command('git checkout master 2>&1')

          assert_commit_subject(commit_message)
          assert_commit_author('Some body')
          assert_commit_email('somebody@example.com')
        end
      end

      it 'should push changes to specified branch successfully' do
        commit_message = 'Make some changes'
        braid_output = nil
        in_dir(@repository_dir) do
          with_editor_message(commit_message) do
            braid_output = run_command("#{BRAID_BIN} push skit1 --branch MyBranch")
          end
        end
        expect(braid_output).to match(/Braid: Cloning mirror with local changes./)
        expect(braid_output).to match(/Make some changes/)
        expect(braid_output).to match(/Braid: Pushing changes to remote branch MyBranch./)

        assert_no_diff("#{FIXTURE_PATH}/skit1/#{@file_name}", "#{@vendor_repository_dir}/#{@file_name}")
        assert_no_diff("#{FIXTURE_PATH}/skit1.1/#{@file_name}", "#{@repository_dir}/skit1/#{@file_name}")

        in_dir(@vendor_repository_dir) do
          run_command('git checkout MyBranch 2>&1')

          assert_commit_subject(commit_message)
          assert_commit_author('Some body')
          assert_commit_email('somebody@example.com')
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
      it 'should halt before attempting to push changes' do
        braid_output = nil
        in_dir(@repository_dir) do
          with_editor_message('Make some changes') do
            braid_output = run_command("#{BRAID_BIN} push skit1")
          end
        end
        expect(braid_output).to match(/Braid: Mirror is not up to date. Stopping./)

        assert_no_diff("#{FIXTURE_PATH}/skit1.2/#{@file_name}", "#{TMP_PATH}/skit1/#{@file_name}")
      end
    end
  end

  describe 'from a git repository braided into subdirectory' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny', :name => 'Some body', :email => 'somebody@example.com')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')
      @file_name = 'layouts/layout.liquid'

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir} --path layouts skit-layouts")
      end

      in_dir(@vendor_repository_dir) do
        run_command('git config receive.denyCurrentBranch updateInstead')
      end

      update_dir_from_fixture('shiny/skit-layouts', 'skit1.1/layouts')
      in_dir(@repository_dir) do
        run_command('git add *')
        run_command('git commit -m "Make some changes to vendored files"')
      end
    end

    context 'with remote updtodate' do
      it 'should push changes successfully' do
        braid_output = nil
        commit_message = 'Make some changes'
        in_dir(@repository_dir) do
          with_editor_message(commit_message) do
            braid_output = run_command("#{BRAID_BIN} push skit-layouts")
          end
        end
        expect(braid_output).to match(/Braid: Cloning mirror with local changes./)
        expect(braid_output).to match(/Make some changes/)
        expect(braid_output).to match(/Braid: Pushing changes to remote branch master./)

        assert_no_diff("#{FIXTURE_PATH}/skit1.1/#{@file_name}", "#{@repository_dir}/skit-layouts/layout.liquid")
        assert_no_diff("#{FIXTURE_PATH}/skit1.1/#{@file_name}", "#{@vendor_repository_dir}/#{@file_name}")

        in_dir(@vendor_repository_dir) do
          run_command('git checkout master 2>&1')

          assert_commit_subject(commit_message)
          assert_commit_author('Some body')
          assert_commit_email('somebody@example.com')
        end
      end
    end
  end

  describe 'from a git repository braided into a single file' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny', :name => 'Some body', :email => 'somebody@example.com')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')
      @file_name = 'layouts/layout.liquid'

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir} --path layouts/layout.liquid skit-layout.liquid")
      end

      in_dir(@vendor_repository_dir) do
        run_command('git config receive.denyCurrentBranch updateInstead')
      end

      FileUtils.cp_r(File.join(FIXTURE_PATH, 'skit1.1x') + '/layouts/layout.liquid', "#{@repository_dir}/skit-layout.liquid",
        {preserve: true})
      in_dir(@repository_dir) do
        run_command('git add *')
        run_command('git commit -m "Make some changes to vendored files"')
      end
    end

    context 'with remote updtodate' do
      it 'should push changes successfully' do
        braid_output = nil
        commit_message = 'Make some changes'
        in_dir(@repository_dir) do
          with_editor_message(commit_message) do
            braid_output = run_command("#{BRAID_BIN} push skit-layout.liquid")
          end
        end
        expect(braid_output).to match(/Braid: Cloning mirror with local changes./)
        expect(braid_output).to match(/Make some changes/)
        expect(braid_output).to match(/Braid: Pushing changes to remote branch master./)

        assert_no_diff("#{FIXTURE_PATH}/skit1.1x/#{@file_name}", "#{@repository_dir}/skit-layout.liquid")
        assert_no_diff("#{FIXTURE_PATH}/skit1.1x/#{@file_name}", "#{@vendor_repository_dir}/#{@file_name}")

        in_dir(@vendor_repository_dir) do
          run_command('git checkout master 2>&1')

          if filemode_enabled
            expect(File.stat(@file_name).mode & 0100).to eq(0100)
          end

          assert_commit_subject(commit_message)
          assert_commit_author('Some body')
          assert_commit_email('somebody@example.com')
        end
      end
    end
  end

  describe 'from a git repository braided in as a tag' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny', :name => 'Some body', :email => 'somebody@example.com')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')
      in_dir(@vendor_repository_dir) do
        run_command('git tag v1')
      end
      @file_name = 'layouts/layout.liquid'

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir} --tag v1")
      end

      in_dir(@vendor_repository_dir) do
        run_command('git config receive.denyCurrentBranch updateInstead')
      end

      update_dir_from_fixture('shiny/skit1', 'skit1.1')
      in_dir(@repository_dir) do
        run_command('git add *')
        run_command('git commit -m "Make some changes to vendored files"')
      end
    end

    context 'with remote updtodate' do
      it 'should fail tring to push without specifying branch' do
        braid_output = nil
        commit_message = 'Make some changes'
        in_dir(@repository_dir) do
          with_editor_message(commit_message) do
            braid_output = `#{BRAID_BIN} push skit1`
          end
        end
        expect(braid_output).to match(/Braid: Error: mirror is based off a tag. Can not push to a tag: skit1/)

        assert_no_diff("#{FIXTURE_PATH}/skit1.1/#{@file_name}", "#{@repository_dir}/skit1/#{@file_name}")
        assert_no_diff("#{FIXTURE_PATH}/skit1/#{@file_name}", "#{@vendor_repository_dir}/#{@file_name}")
      end

      it 'should push changes to specified branch successfully' do
        commit_message = 'Make some changes'
        braid_output = nil
        in_dir(@repository_dir) do
          with_editor_message(commit_message) do
            braid_output = run_command("#{BRAID_BIN} push skit1 --branch MyBranch")
          end
        end
        expect(braid_output).to match(/Braid: Cloning mirror with local changes./)
        expect(braid_output).to match(/Make some changes/)
        expect(braid_output).to match(/Braid: Pushing changes to remote branch MyBranch./)

        assert_no_diff("#{FIXTURE_PATH}/skit1/#{@file_name}", "#{@vendor_repository_dir}/#{@file_name}")
        assert_no_diff("#{FIXTURE_PATH}/skit1.1/#{@file_name}", "#{@repository_dir}/skit1/#{@file_name}")

        in_dir(@vendor_repository_dir) do
          run_command('git checkout MyBranch 2>&1')

          assert_commit_subject(commit_message)
          assert_commit_author('Some body')
          assert_commit_email('somebody@example.com')
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
          run_command('git tag -f v1')
        end
      end

      it 'should halt before attempting to push changes' do
        braid_output = nil
        in_dir(@repository_dir) do
          with_editor_message('Make some changes') do
            braid_output = run_command("#{BRAID_BIN} push skit1 --branch MyBranch")
          end
        end
        expect(braid_output).to match(/Braid: Mirror is not up to date. Stopping./)

        assert_no_diff("#{FIXTURE_PATH}/skit1.2/#{@file_name}", "#{TMP_PATH}/skit1/#{@file_name}")
      end
    end
  end
end
