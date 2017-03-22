require File.dirname(__FILE__) + '/../integration_helper'

describe 'Updating a mirror' do

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

      update_dir_from_fixture('skit1', 'skit1.1')
      in_dir(@vendor_repository_dir) do
        run_command('git add *')
        run_command('git commit -m "change default color"')
      end

      update_dir_from_fixture('skit1', 'skit1.2')
      in_dir(@vendor_repository_dir) do
        run_command('git add *')
        run_command('git commit -m "add a happy note"')
      end
    end

    context 'with no project-specific changes' do
      it 'should add the files and commit' do
        in_dir(@repository_dir) do
          run_command("#{BRAID_BIN} update skit1")
        end

        assert_no_diff("#{FIXTURE_PATH}/skit1.2/#{@file_name}", "#{@repository_dir}/skit1/#{@file_name}")

        output = run_command('git log --pretty=oneline').split("\n")
        output.length.should == 3
        output[0].should =~ /^[0-9a-f]{40} Braid: Update mirror 'skit1' to '[0-9a-f]{7}'$/

        # No temporary commits should be added to the reflog.
        output = `git log -g --pretty=oneline`.split("\n")
        output.length.should == 3
      end
    end

    context 'with mergeable changes to the same file' do
      it 'should auto-merge and commit' do
        run_command("cp #{File.join(FIXTURE_PATH, 'shiny_skit1_mergeable', @file_name)} #{File.join(TMP_PATH, 'shiny', 'skit1', @file_name)}")

        in_dir(@repository_dir) do
          run_command("git commit -a -m 'mergeable change'")
          run_command("#{BRAID_BIN} update skit1")
        end

        assert_no_diff("#{FIXTURE_PATH}/shiny_skit1.2_merged/#{@file_name}", "#{@repository_dir}/skit1/#{@file_name}")

        output = run_command('git log --pretty=oneline').split("\n")
        output.length.should == 4  # plus 'mergeable change'
        output[0].should =~ /Braid: Update mirror 'skit1' to '[0-9a-f]{7}'/
      end
    end

    context 'with conflicting changes' do
      it 'should leave conflict markup with the target revision' do
        run_command("cp #{File.join(FIXTURE_PATH, 'shiny_skit1_conflicting', @file_name)} #{File.join(TMP_PATH, 'shiny', 'skit1', @file_name)}")

        target_revision = nil
        in_dir(@vendor_repository_dir) do
          target_revision = run_command('git rev-parse HEAD')
        end

        braid_output = nil
        in_dir(@repository_dir) do
          run_command("git commit -a -m 'conflicting change'")
          braid_output = run_command("#{BRAID_BIN} update skit1")
        end
        braid_output.should =~ /Caught merge error\. Breaking\./

        run_command("grep -q '>>>>>>> #{target_revision}' #{File.join(TMP_PATH, 'shiny', 'skit1', @file_name)}")
      end
    end

    # Regression test for https://github.com/cristibalan/braid/issues/41.
    context 'with a convergent deletion' do
      it 'should not detect a bogus rename' do
        in_dir(@vendor_repository_dir) do
          run_command('git rm layouts/layout.liquid')
          run_command('git commit -m "delete"')
        end
        in_dir(@repository_dir) do
          run_command('git rm skit1/layouts/layout.liquid')
          run_command('git commit -m "delete here too"')
        end

        # Without the fix, when git diffs the base and local trees, it will
        # think skit1/layouts/layout.liquid was renamed to
        # other-skit/layout.liquid, resulting in a rename-delete conflict.
        braid_output = nil
        in_dir(@repository_dir) do
          braid_output = run_command("#{BRAID_BIN} update skit1")
        end
        braid_output.should_not =~ /Caught merge error\. Breaking\./
      end
    end
  end
end
