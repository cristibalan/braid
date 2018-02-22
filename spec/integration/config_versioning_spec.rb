require File.dirname(__FILE__) + '/integration_helper'

describe 'Config versioning:' do

  before do
    FileUtils.rm_rf(TMP_PATH)
    FileUtils.mkdir_p(TMP_PATH)
  end

  # Workaround for Braid writing .braids.json with LF line endings on Windows,
  # while the .braids.json files in the fixtures get converted to CRLF under Git
  # for Windows recommended settings.
  # https://github.com/cristibalan/braid/issues/77
  def assert_no_diff_in_braids(file1, file2)
    assert_no_diff(file1, file2, "--ignore-trailing-space")
  end

  describe 'read-only command' do

    it "from future config version should fail" do
      @repository_dir = create_git_repo_from_fixture('shiny-conf-future')

      in_dir(@repository_dir) do
        output = run_command_expect_failure("#{BRAID_BIN} diff skit1")
        expect(output).to match(/is too old to understand/)
      end
    end

    it "from old config version with no breaking changes should work" do
      @repository_dir = create_git_repo_from_fixture('shiny-conf-yaml')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')

      vendor_revision = nil
      in_dir(@vendor_repository_dir) do
        vendor_revision = run_command("git rev-parse HEAD")
      end

      in_dir(@repository_dir) do
        # For a real command to work, we have to substitute the URL and revision
        # of the real vendor repository we created on this run of the test.  The
        # below looks marginally easier than using the real YAML parser.
        braids_content = nil
        File.open('.braids', 'rb') do |f|
          braids_content = f.read
        end
        braids_content = braids_content.sub(/revision:.*$/, "revision: #{vendor_revision}")
        braids_content = braids_content.sub(/url:.*$/, "url: file://#{@vendor_repository_dir}")
        File.open('.braids', 'wb') do |f|
          f.write braids_content
        end

        output = run_command("#{BRAID_BIN} diff skit1")
        expect(output).to eq('')  # no diff
      end
    end

    it "from old config version with breaking changes should fail" do
      @repository_dir = create_git_repo_from_fixture('shiny-conf-breaking-changes')

      in_dir(@repository_dir) do
        output = run_command_expect_failure("#{BRAID_BIN} diff skit1")
        expect(output).to match(/no longer supports a feature/)
      end
    end

  end

  describe 'write command' do

    it "from future config version should fail" do
      @repository_dir = create_git_repo_from_fixture('shiny-conf-future')

      in_dir(@repository_dir) do
        output = run_command_expect_failure("#{BRAID_BIN} update skit1")
        expect(output).to match(/is too old to understand/)
      end
    end

    it "from old config version with no breaking changes should fail" do
      @repository_dir = create_git_repo_from_fixture('shiny-conf-yaml')

      in_dir(@repository_dir) do
        output = run_command_expect_failure("#{BRAID_BIN} update skit1")
        expect(output).to match(/force other developers on your project to upgrade Braid/)
      end
    end

    it "from old config version with breaking changes should fail" do
      @repository_dir = create_git_repo_from_fixture('shiny-conf-breaking-changes')

      in_dir(@repository_dir) do
        output = run_command_expect_failure("#{BRAID_BIN} update skit1")
        expect(output).to match(/no longer supports a feature/)
      end
    end

  end

  describe '"braid upgrade-config"' do

    it "from Braid 0.7.1 (.braids YAML) should produce the expected configuration" do
      @repository_dir = create_git_repo_from_fixture('shiny-conf-yaml')

      in_dir(@repository_dir) do
        output = run_command("#{BRAID_BIN} upgrade-config")
        # Check this on one of the test cases.
        expect(output).to match(/Configuration upgrade complete\./)
        expect(File.exists?(".braids")).to eq(false)
        assert_no_diff_in_braids(".braids.json", "expected.braids.json")
      end
    end

    it "from Braid 1.0.0 (.braids JSON) should produce the expected configuration" do
      @repository_dir = create_git_repo_from_fixture('shiny-conf-json-old-name')

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} upgrade-config")
        expect(File.exists?(".braids")).to eq(false)
        assert_no_diff_in_braids(".braids.json", "expected.braids.json")
      end
    end

    it "from Braid 1.0.9 (.braids.json) with old-style lock should produce the expected configuration" do
      @repository_dir = create_git_repo_from_fixture('shiny-conf-1.0.9-lock')

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} upgrade-config")
        assert_no_diff_in_braids(".braids.json", "expected.braids.json")
      end
    end

    it "from Braid 1.0.9 (.braids.json) with old-style lock with --dry-run should print info without performing the upgrade" do
      @repository_dir = create_git_repo_from_fixture('shiny-conf-1.0.9-lock')

      in_dir(@repository_dir) do
        output = run_command("#{BRAID_BIN} upgrade-config --dry-run")
        expect(output).to match(/Your configuration file will be upgraded from configuration version 0 to 1\./)
        expect(output).not_to match(/The following breaking changes/)
        # Instructions should not include --allow-breaking-changes if it isn't necessary.
        expect(output).to match(/Run 'braid upgrade-config'/)
        assert_no_diff_in_braids(".braids.json", "#{FIXTURE_PATH}/shiny-conf-1.0.9-lock/.braids.json")
      end
    end

    it "with breaking changes and --dry-run should print info without performing the upgrade" do
      @repository_dir = create_git_repo_from_fixture('shiny-conf-breaking-changes')

      in_dir(@repository_dir) do
        output = run_command("#{BRAID_BIN} upgrade-config --dry-run")
        expect(output).to match(/The following breaking changes/)
        expect(output).to match(/Spoon-Knife.*Subversion/)
        expect(output).to match(/skit1.*full-history/)
        expect(output).to match(/Run 'braid upgrade-config --allow-breaking-changes'/)
        assert_no_diff(".braids", "#{FIXTURE_PATH}/shiny-conf-breaking-changes/.braids")
        expect(File.exists?(".braids.json")).to eq(false)
      end
    end

    it "with breaking changes should fail" do
      @repository_dir = create_git_repo_from_fixture('shiny-conf-breaking-changes')

      in_dir(@repository_dir) do
        output = run_command_expect_failure("#{BRAID_BIN} upgrade-config")
        expect(output).to match(/The following breaking changes/)
        expect(output).to match(/Spoon-Knife.*Subversion/)
        expect(output).to match(/skit1.*full-history/)
        expect(output).to match(/You must pass --allow-breaking-changes/)
        # `braid upgrade-config` should not have changed any files.
        assert_no_diff(".braids", "#{FIXTURE_PATH}/shiny-conf-breaking-changes/.braids")
        expect(File.exists?(".braids.json")).to eq(false)
      end
    end

    it "with breaking changes and --allow-breaking-changes should produce the expected configuration" do
      @repository_dir = create_git_repo_from_fixture('shiny-conf-breaking-changes')

      in_dir(@repository_dir) do
        output = run_command("#{BRAID_BIN} upgrade-config --allow-breaking-changes")
        expect(output).to match(/The following breaking changes/)
        expect(output).to match(/Spoon-Knife.*Subversion/)
        expect(output).to match(/skit1.*full-history/)
        expect(output).to match(/Configuration upgrade complete\./)
        expect(File.exists?(".braids")).to eq(false)
        assert_no_diff_in_braids(".braids.json", "expected.braids.json")
      end
    end

    it "from future config version should fail" do
      @repository_dir = create_git_repo_from_fixture('shiny-conf-future')

      in_dir(@repository_dir) do
        output = run_command_expect_failure("#{BRAID_BIN} upgrade-config")
        expect(output).to match(/is too old to understand/)
      end
    end

    it "from current config version should do nothing and print expected message" do
      # Generate a current-version configuration by adding a mirror.
      @repository_dir = create_git_repo_from_fixture('shiny')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir}")
        output = run_command("#{BRAID_BIN} upgrade-config")
        expect(output).to match(/already at the current configuration version/)
      end
    end

    it "with no Braid configuration should do nothing and print expected message" do
      @repository_dir = create_git_repo_from_fixture('shiny')

      in_dir(@repository_dir) do
        output = run_command("#{BRAID_BIN} upgrade-config")
        expect(output).to match(/has no Braid configuration file/)
        expect(File.exists?(".braids.json")).to eq(false)
      end
    end

  end

end
