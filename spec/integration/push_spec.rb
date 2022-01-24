require File.dirname(__FILE__) + '/integration_helper'

BRAID_PUSH_USES_SPARSE_CHECKOUT = git_require_version('2.27')

describe 'Pushing to a mirror' do

  # This code needs to run before the `around` hook in the required-filter test
  # that sets up the virtual home directory inside TMP_PATH, but per-example
  # `before` hooks always run after `around` hooks.  So make this an `around`
  # hook just to get it to run at the time we want.
  around do |example|
    FileUtils.rm_rf(TMP_PATH)
    FileUtils.mkdir_p(TMP_PATH)
    example.run
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
        preserve: true)
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

  describe 'from a git repository with a required filter', :if => BRAID_PUSH_USES_SPARSE_CHECKOUT do
    # This tests that a Git filter that is configured as "required" at the user
    # account level but fails without additional repository-level configuration
    # (which currently may be the case for Git LFS:
    # https://github.com/cristibalan/braid/pull/98) does not interfere with
    # pushing using a temporary repository. Braid achieves this by using an
    # empty sparse checkout in the temporary repository to avoid triggering the
    # filter.

    around do |example|
      # In order to simulate configuring the filter at the user account level
      # without modifying the user's real Git configuration, we have to
      # temporarily change $HOME.  Unfortunately, this may break other things
      # that need the real $HOME.  So far, the only problem we've seen is the
      # Braid subprocess not finding Ruby gems, and setting $GEM_PATH seems to
      # be a sufficient workaround.
      orig_gem_path = run_command('gem environment gempath').strip
      virtual_home = File.join(TMP_PATH, 'home')
      FileUtils.mkdir_p(virtual_home)
      Braid::Operations::with_modified_environment({
        'HOME' => virtual_home,
        # If the user has an $XDG_CONFIG_HOME-based configuration file, ensure
        # that Git doesn't use it, to maintain consistency with not using the
        # original ~/.gitconfig.  TODO: Would it be better to `include` both
        # files in case they have a setting that we actually need?
        'XDG_CONFIG_HOME' => nil,
        'GEM_PATH' => orig_gem_path
      }) do
        example.run
      end
    end

    before do
      # create_git_repo_from_fixture('skit1_with_filter') would check out the
      # working tree and trigger the broken filter before we have an opportunity
      # to turn it off in the repository configuration.  Avoiding this problem
      # would take some extra code, so as a workaround, we just don't configure
      # the filter until after that step. :/
      @vendor_repository_dir = create_git_repo_from_fixture('skit1_with_filter')

      # Configure the broken filter globally.  Here, `false` is the command that
      # always exits 1.
      run_command('git config --global filter.broken.clean false')
      run_command('git config --global filter.broken.smudge false')
      run_command('git config --global filter.broken.required true')

      # This won't trigger the filter because the .gitattributes file is only in
      # the vendor repository.
      @repository_dir = create_git_repo_from_fixture('shiny', :name => 'Some body', :email => 'somebody@example.com')
      @file_name = 'layouts/layout.liquid'

      in_dir(@repository_dir) do
        # Make the filter a no-op in the superproject repository.
        run_command('git config filter.broken.clean cat')
        run_command('git config filter.broken.smudge cat')

        run_command("#{BRAID_BIN} add #{@vendor_repository_dir} skit1")
      end

      in_dir(@vendor_repository_dir) do
        run_command('git config receive.denyCurrentBranch updateInstead')
      end

      update_dir_from_fixture('shiny/skit1', 'skit1.1_with_filter')
      in_dir(@repository_dir) do
        run_command('git add *')
        run_command('git commit -m "Make some changes to vendored files"')
      end
    end

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

      assert_no_diff("#{FIXTURE_PATH}/skit1.1_with_filter/#{@file_name}", "#{@repository_dir}/skit1/#{@file_name}")
      assert_no_diff("#{FIXTURE_PATH}/skit1.1_with_filter/#{@file_name}", "#{@vendor_repository_dir}/#{@file_name}")

      in_dir(@vendor_repository_dir) do
        run_command('git checkout master 2>&1')

        assert_commit_subject(commit_message)
        assert_commit_author('Some body')
        assert_commit_email('somebody@example.com')
      end
    end
  end
end
