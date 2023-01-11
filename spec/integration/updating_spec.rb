require File.dirname(__FILE__) + '/integration_helper'

describe 'Updating a mirror' do

  before do
    FileUtils.rm_rf(TMP_PATH)
    FileUtils.mkdir_p(TMP_PATH)
  end

  describe 'with a git repository' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny', :name => 'Some body', :email => 'somebody@example.com')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')
      @head_version = nil
      in_dir(@vendor_repository_dir) do
        run_command('git tag v1')
        @head_version = run_command('git rev-parse HEAD')
      end
      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir}")
      end
    end

    it 'should generate an error if --head parameter passed' do
      output = nil
      in_dir(@repository_dir) do
        output = `#{BRAID_BIN} update skit1 --head 2>&1`
      end

      expect(output).to match(/^Braid: Error: Do not specify --head option anymore. Please use '--branch MyBranch' to track a branch or '--tag MyTag' to track a branch$/)
    end

    it 'should generate an error if both tag and revision specified' do
      output = nil
      in_dir(@repository_dir) do
        output = `#{BRAID_BIN} update skit1 --tag v1 --revision #{@head_version} 2>&1`
      end

      expect(output).to match(/^Braid: Error: Can not update mirror specifying both a revision and a tag$/)
    end

    it 'should generate an error if both branch and revision specified' do
      output = nil
      in_dir(@repository_dir) do
        output = `#{BRAID_BIN} update skit1 --branch master --tag v1`
      end

      expect(output).to match(/^Braid: Error: Can not update mirror specifying both a branch and a tag$/)
    end
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

        output = nil
        in_dir(@repository_dir) do
          output = run_command('git log --pretty=oneline').split("\n")
        end
        expect(output.length).to eq(3)
        expect(output[0]).to match(/^[0-9a-f]{40} Braid: Update mirror 'skit1' to '[0-9a-f]{7}'$/)

        # No temporary commits should be added to the reflog.
        output = nil
        in_dir(@repository_dir) do
          output = `git log -g --pretty=oneline`.split("\n")
        end
        expect(output.length).to eq(3)
      end
    end

    context 'with mergeable changes to the same file' do
      it 'should auto-merge and commit' do
        run_command("cp #{File.join(FIXTURE_PATH, 'shiny_skit1_mergeable', @file_name)} #{File.join(TMP_PATH, 'shiny', 'skit1', @file_name)}")

        in_dir(@repository_dir) do
          run_command('git commit -a -m "mergeable change"')
          run_command("#{BRAID_BIN} update skit1")
        end

        assert_no_diff("#{FIXTURE_PATH}/shiny_skit1.2_merged/#{@file_name}", "#{@repository_dir}/skit1/#{@file_name}")

        output = nil
        in_dir(@repository_dir) do
          output = run_command('git log --pretty=oneline').split("\n")
        end
        expect(output.length).to eq(4) # plus 'mergeable change'
        expect(output[0]).to match(/Braid: Update mirror 'skit1' to '[0-9a-f]{7}'/)
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
          run_command('git commit -a -m "conflicting change"')
          braid_output = run_command("#{BRAID_BIN} update skit1")
        end
        expect(braid_output).to match(/Caught merge error\. Breaking\./)

        run_command("grep -q \">>>>>>> #{target_revision}\" #{File.join(TMP_PATH, 'shiny', 'skit1', @file_name)}")
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
        expect(braid_output).not_to match(/Caught merge error\. Breaking\./)
      end
    end
  end

  describe 'from a git repository with a braid into subdirectory' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')
      @file_name = 'layouts/layout.liquid'

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir} --path layouts skit-layouts")
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
          run_command("#{BRAID_BIN} update skit-layouts")
        end

        assert_no_diff("#{FIXTURE_PATH}/skit1.2/#{@file_name}", "#{@repository_dir}/skit-layouts/layout.liquid")

        output = nil
        in_dir(@repository_dir) do
          output = run_command('git log --pretty=oneline').split("\n")
        end
        expect(output.length).to eq(3)
        expect(output[0]).to match(/^[0-9a-f]{40} Braid: Update mirror 'skit-layouts' to '[0-9a-f]{7}'$/)

        # No temporary commits should be added to the reflog.
        output = nil
        in_dir(@repository_dir) do
          output = `git log -g --pretty=oneline`.split("\n")
        end
        expect(output.length).to eq(3)
      end
    end
  end

  # See the comment in adding_spec.rb regarding tests with paths containing
  # spaces.
  describe 'from a git repository with a braid into subdirectory with paths containing spaces' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny', :directory => 'shiny with spaces')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1_with_space', :directory => 'skit with spaces')
      @file_name = 'layouts/layout.liquid'

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add --path \"lay outs\" \"#{@vendor_repository_dir}\" \"skit lay outs\"")
      end

      update_dir_from_fixture("skit with spaces/lay outs", 'skit1.1/layouts')
      in_dir(@vendor_repository_dir) do
        run_command('git add *')
        run_command('git commit -m "change default color"')
      end

      update_dir_from_fixture("skit with spaces/lay outs", 'skit1.2/layouts')
      in_dir(@vendor_repository_dir) do
        run_command('git add *')
        run_command('git commit -m "add a happy note"')
      end
    end

    context 'with no project-specific changes' do
      it 'should add the files and commit' do
        in_dir(@repository_dir) do
          run_command("#{BRAID_BIN} update \"skit lay outs\"")
        end

        assert_no_diff("#{FIXTURE_PATH}/skit1.2/#{@file_name}", "#{@repository_dir}/skit lay outs/layout.liquid")

        output = nil
        in_dir(@repository_dir) do
          output = run_command('git log --pretty=oneline').split("\n")
        end
        expect(output.length).to eq(3)
        expect(output[0]).to match(/^[0-9a-f]{40} Braid: Update mirror 'skit lay outs' to '[0-9a-f]{7}'$/)

        # No temporary commits should be added to the reflog.
        output = nil
        in_dir(@repository_dir) do
          output = `git log -g --pretty=oneline`.split("\n")
        end
        expect(output.length).to eq(3)
      end
    end
  end

  describe 'from a git repository with a braid of a single file' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')
      @file_name = 'layouts/layout.liquid'

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir} --path layouts/layout.liquid skit-layout.liquid")
      end

      update_dir_from_fixture('skit1', 'skit1.1x')
      in_dir(@vendor_repository_dir) do
        run_command('git add *')
        run_command('git commit -m "change color and file mode"')
      end
    end

    context 'with no project-specific changes' do
      it 'should add the files and commit' do
        in_dir(@repository_dir) do
          run_command("#{BRAID_BIN} update skit-layout.liquid")
        end

        assert_no_diff("#{FIXTURE_PATH}/skit1.1x/#{@file_name}", "#{@repository_dir}/skit-layout.liquid")
        in_dir(@repository_dir) do
          if filemode_enabled
            expect(File.stat('skit-layout.liquid').mode & 0100).to eq(0100)
          end
        end

        output = nil
        in_dir(@repository_dir) do
          output = run_command('git log --pretty=oneline').split("\n")
        end
        expect(output.length).to eq(3)
        expect(output[0]).to match(/^[0-9a-f]{40} Braid: Update mirror 'skit-layout.liquid' to '[0-9a-f]{7}'$/)
      end
    end
  end

  describe 'from a git repository braided in as a tag' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')
      in_dir(@vendor_repository_dir) do
        run_command('git tag v1')
      end
      @file_name = 'layouts/layout.liquid'

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir} --tag v1")
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
        run_command('git tag -f v1')
      end
    end

    context 'with no project-specific changes' do
      it 'should add the files and commit' do
        in_dir(@repository_dir) do
          run_command("#{BRAID_BIN} update skit1")
        end

        assert_no_diff("#{FIXTURE_PATH}/skit1.2/#{@file_name}", "#{@repository_dir}/skit1/#{@file_name}")

        output = nil
        in_dir(@repository_dir) do
          output = run_command('git log --pretty=oneline').split("\n")
        end
        expect(output.length).to eq(3)
        expect(output[0]).to match(/^[0-9a-f]{40} Braid: Update mirror 'skit1' to '[0-9a-f]{7}'$/)

        # No temporary commits should be added to the reflog.
        output = nil
        in_dir(@repository_dir) do
          output = `git log -g --pretty=oneline`.split("\n")
        end
        expect(output.length).to eq(3)
      end
    end

    context 'with mergeable changes to the same file' do
      it 'should auto-merge and commit' do
        run_command("cp #{File.join(FIXTURE_PATH, 'shiny_skit1_mergeable', @file_name)} #{File.join(TMP_PATH, 'shiny', 'skit1', @file_name)}")

        in_dir(@repository_dir) do
          run_command('git commit -a -m "mergeable change"')
          run_command("#{BRAID_BIN} update skit1")
        end

        assert_no_diff("#{FIXTURE_PATH}/shiny_skit1.2_merged/#{@file_name}", "#{@repository_dir}/skit1/#{@file_name}")

        output = nil
        in_dir(@repository_dir) do
          output = run_command('git log --pretty=oneline').split("\n")
        end
        expect(output.length).to eq(4) # plus 'mergeable change'
        expect(output[0]).to match(/Braid: Update mirror 'skit1' to '[0-9a-f]{7}'/)
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
          run_command('git commit -a -m "conflicting change"')
          braid_output = run_command("#{BRAID_BIN} update skit1")
        end
        expect(braid_output).to match(/Caught merge error\. Breaking\./)

        run_command("grep -q '>>>>>>> #{target_revision}' #{File.join(TMP_PATH, 'shiny', 'skit1', @file_name)}")
      end
    end
  end

  tracking_strategy =
    {
      'branch' => 'master',
      'tag' => 'v1',
      'revision' => nil,
    }

  tracking_strategy.each_pair do |initial_strategy, initial_value|
    describe "from a git repository from tracking strategy #{initial_strategy} '#{initial_value}'" do
      before do
        @repository_dir = create_git_repo_from_fixture('shiny')
        @vendor_repository_dir = create_git_repo_from_fixture('skit1')
        @file_name = 'layouts/layout.liquid'

        @initial_revision = nil
        in_dir(@vendor_repository_dir) do
          run_command('git tag v1')
          @initial_revision = run_command('git rev-parse HEAD').strip
        end
        in_dir(@repository_dir) do
          run_command("#{BRAID_BIN} add #{@vendor_repository_dir} --#{initial_strategy} #{initial_value || @initial_revision}")
        end

        update_dir_from_fixture('skit1', 'skit1.1')
        in_dir(@vendor_repository_dir) do
          run_command('git add *')
          run_command('git commit -m "change default color"')
        end

        @target_revision = nil
        update_dir_from_fixture('skit1', 'skit1.2')
        in_dir(@vendor_repository_dir) do
          run_command('git add *')
          run_command('git commit -m "add a happy note"')
          @target_revision = run_command('git rev-parse HEAD').strip
          run_command('git tag -f v1')
        end
      end

      context 'with no project-specific changes' do
        if initial_strategy != 'revision'
          it 'should add the files and commit' do
            in_dir(@repository_dir) do
              run_command("#{BRAID_BIN} update skit1")
            end

            assert_no_diff("#{FIXTURE_PATH}/skit1.2/#{@file_name}", "#{@repository_dir}/skit1/layouts/layout.liquid")

            output = nil
            in_dir(@repository_dir) do
              output = run_command('git log --pretty=oneline').split("\n")
            end
            expect(output.length).to eq(3)
            expect(output[0]).to match(/^[0-9a-f]{40} Braid: Update mirror 'skit1' to '[0-9a-f]{7}'$/)

            # No temporary commits should be added to the reflog.
            output = nil
            in_dir(@repository_dir) do
              output = `git log -g --pretty=oneline`.split("\n")
            end
            expect(output.length).to eq(3)
          end

          context 'with mergeable changes to the same file' do
            it 'should auto-merge and commit' do
              run_command("cp #{File.join(FIXTURE_PATH, 'shiny_skit1_mergeable', @file_name)} #{File.join(TMP_PATH, 'shiny', 'skit1', @file_name)}")

              in_dir(@repository_dir) do
                run_command('git commit -a -m "mergeable change"')
                run_command("#{BRAID_BIN} update skit1")
              end

              assert_no_diff("#{FIXTURE_PATH}/shiny_skit1.2_merged/#{@file_name}", "#{@repository_dir}/skit1/#{@file_name}")

              output = nil
              in_dir(@repository_dir) do
                output = run_command('git log --pretty=oneline').split("\n")
              end
              expect(output.length).to eq(4) # plus 'mergeable change'
              expect(output[0]).to match(/Braid: Update mirror 'skit1' to '[0-9a-f]{7}'/)
            end
          end
        else
          it 'should not change files as revision not changed' do
            in_dir(@repository_dir) do
              run_command("#{BRAID_BIN} update skit1 --verbose")
            end

            assert_no_diff("#{FIXTURE_PATH}/skit1/#{@file_name}", "#{@repository_dir}/skit1/#{@file_name}")

            output = nil
            in_dir(@repository_dir) do
              output = run_command('git log --pretty=oneline').split("\n")
            end
            expect(output.length).to eq(2)

            # No temporary commits should be added to the reflog.
            output = nil
            in_dir(@repository_dir) do
              output = `git log -g --pretty=oneline`.split("\n")
            end
            expect(output.length).to eq(2)
          end
        end
      end

      tracking_strategy.each_pair do |target_strategy, target_value|
        describe "to a tracking strategy #{target_strategy} '#{target_value}'" do
          it 'should add the files and commit' do
            output = nil
            in_dir(@repository_dir) do
              output = run_command("#{BRAID_BIN} update skit1 --#{target_strategy} #{target_value || @target_revision}").split("\n")
            end

            index = 0
            expect(output[index]).to match(/^Braid: Updating mirror 'skit1'.$/)

            if initial_strategy != target_strategy || target_strategy == 'revision'
              index = index + 1
              expect(output[index]).to match(/^Braid: Switching mirror 'skit1' to #{target_strategy} '#{target_value || @target_revision}' from #{initial_strategy} '#{initial_value || @initial_revision}'.$/)
            end
            index = index + 1
            expect(output[index]).to match(/^Braid: Updated mirror to '[0-9a-f]{7}'.$/)

            assert_no_diff("#{FIXTURE_PATH}/skit1.2/#{@file_name}", "#{@repository_dir}/skit1/layouts/layout.liquid")

            output = nil
            in_dir(@repository_dir) do
              output = run_command('git log --pretty=oneline').split("\n")
            end
            expect(output.length).to eq(3)
            expect(output[0]).to match(/^[0-9a-f]{40} Braid: Update mirror 'skit1' to '[0-9a-f]{7}'$/)

            # No temporary commits should be added to the reflog.
            output = nil
            in_dir(@repository_dir) do
              output = `git log -g --pretty=oneline`.split("\n")
            end
            expect(output.length).to eq(3)
          end
        end
      end
    end
  end
end
