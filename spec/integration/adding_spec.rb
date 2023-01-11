require File.dirname(__FILE__) + '/integration_helper'

describe 'Adding a mirror in a clean repository' do

  before do
    FileUtils.rm_rf(TMP_PATH)
    FileUtils.mkdir_p(TMP_PATH)
  end

  describe 'from a git repository' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny', :name => 'Some body', :email => 'somebody@example.com')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir}")
      end
    end

    it 'should add the files and commit' do
      assert_no_diff("#{FIXTURE_PATH}/skit1/layouts/layout.liquid", "#{@repository_dir}/skit1/layouts/layout.liquid")

      in_dir(@repository_dir) do
        assert_commit_subject(/Braid: Add mirror 'skit1' at '[0-9a-f]{7}'/)
        assert_commit_author('Some body')
        assert_commit_email('somebody@example.com')
      end
    end

    it 'should create .braids.json and add the mirror to it' do
      braids = YAML::load_file("#{@repository_dir}/.braids.json")
      expect(braids['config_version']).to be_kind_of(Numeric)
      mirror_obj = braids['mirrors']['skit1']
      expect(mirror_obj['url']).to eq(@vendor_repository_dir)
      expect(mirror_obj['revision']).not_to be_nil
      expect(mirror_obj['branch']).to eq('master')
      expect(mirror_obj['tag']).to be_nil
      expect(mirror_obj['path']).to be_nil
    end
  end

  describe 'from a git repository with a different default branch name' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny', :name => 'Some body', :email => 'somebody@example.com')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')
      in_dir(@vendor_repository_dir) do
        run_command('git branch -m main')
      end

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir}")
      end
    end

    it 'should add the files and commit' do
      assert_no_diff("#{FIXTURE_PATH}/skit1/layouts/layout.liquid", "#{@repository_dir}/skit1/layouts/layout.liquid")

      in_dir(@repository_dir) do
        assert_commit_subject(/Braid: Add mirror 'skit1' at '[0-9a-f]{7}'/)
        assert_commit_author('Some body')
        assert_commit_email('somebody@example.com')
      end
    end

    it 'should create .braids.json and add the mirror to it' do
      braids = YAML::load_file("#{@repository_dir}/.braids.json")
      expect(braids['config_version']).to be_kind_of(Numeric)
      mirror_obj = braids['mirrors']['skit1']
      expect(mirror_obj['url']).to eq(@vendor_repository_dir)
      expect(mirror_obj['revision']).not_to be_nil
      expect(mirror_obj['branch']).to eq('main')
      expect(mirror_obj['tag']).to be_nil
      expect(mirror_obj['path']).to be_nil
    end
  end

  describe 'from a git repository with a detached HEAD' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny', :name => 'Some body', :email => 'somebody@example.com')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')
      in_dir(@vendor_repository_dir) do
        run_command('git checkout --quiet HEAD^{commit}')
      end
    end

    it 'should generate an error that the default branch cannot be detected' do
      output = nil
      in_dir(@repository_dir) do
        output = `#{BRAID_BIN} add #{@vendor_repository_dir}`
      end

      expect(output).to match(/^Braid: Error: Failed to detect the default branch/)
    end
  end

  describe 'from a subdirectory in a git repository' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny', :name => 'Some body', :email => 'somebody@example.com')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add --path layouts #{@vendor_repository_dir} skit-layouts")
      end
    end

    it 'should add the files and commit' do
      assert_no_diff("#{FIXTURE_PATH}/skit1/layouts/layout.liquid", "#{@repository_dir}/skit-layouts/layout.liquid")

      in_dir(@repository_dir) do
        assert_commit_subject(/Braid: Add mirror 'skit-layouts' at '[0-9a-f]{7}'/)
        assert_commit_author('Some body')
        assert_commit_email('somebody@example.com')
      end
    end

    it 'should create .braids.json and add the mirror to it' do
      braids = YAML::load_file("#{@repository_dir}/.braids.json")
      expect(braids['config_version']).to be_kind_of(Numeric)
      mirror_obj = braids['mirrors']['skit-layouts']
      expect(mirror_obj['url']).to eq(@vendor_repository_dir)
      expect(mirror_obj['revision']).not_to be_nil
      expect(mirror_obj['branch']).to eq('master')
      expect(mirror_obj['tag']).to be_nil
      expect(mirror_obj['path']).to eq('layouts')
    end
  end

  describe 'from a nonexistent subdirectory in a git repository' do
    it 'should print a meaningful error message' do
      @repository_dir = create_git_repo_from_fixture('shiny', :name => 'Some body', :email => 'somebody@example.com')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')

      in_dir(@repository_dir) do
        output = run_command_expect_failure("#{BRAID_BIN} add --path nonexistent #{@vendor_repository_dir} skit-layouts")
        # Per the TODO in get_tree_item in operations.rb, this message is not
        # great, but it sure beats what happened before (a NoMethodError on
        # nil).
        expect(output).to match(/No tree item exists at the given path/)
      end
    end
  end

  # We have one test case per Braid command that Braid now handles spaces in
  # file paths correctly.  This is a compromise: if we tried to test spaces in
  # combination with every Braid feature, we might be able to catch more bugs,
  # but maintaining so many tests would be unmanageable.
  #
  # We put a space everywhere we can think of: in the upstream and downstream
  # repository paths and in the paths of the mirror within the upstream and
  # downstream repositories.
  describe 'from a subdirectory in a git repository with paths containing spaces' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny', :directory => 'shiny with spaces',
        :name => 'Some body', :email => 'somebody@example.com')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1_with_space', :directory => 'skit with spaces')

      in_dir(@repository_dir) do
        # Take the opportunity to additionally test that --verbose prints the
        # commands appropriately escaped.
        output = run_command("#{BRAID_BIN} add --verbose --path \"lay outs\" \"#{@vendor_repository_dir}\" \"skit lay outs\"")
        expect(output).to match(/git read-tree --prefix\\=skit\\ lay\\ outs/)
      end
    end

    it 'should add the files and commit' do
      assert_no_diff("#{FIXTURE_PATH}/skit1_with_space/lay outs/layout.liquid", "#{@repository_dir}/skit lay outs/layout.liquid")

      in_dir(@repository_dir) do
        assert_commit_subject(/Braid: Add mirror 'skit lay outs' at '[0-9a-f]{7}'/)
        assert_commit_author('Some body')
        assert_commit_email('somebody@example.com')
      end
    end

    it 'should create .braids.json and add the mirror to it' do
      braids = YAML::load_file("#{@repository_dir}/.braids.json")
      expect(braids['config_version']).to be_kind_of(Numeric)
      mirror_obj = braids['mirrors']['skit lay outs']
      expect(mirror_obj['url']).to eq(@vendor_repository_dir)
      expect(mirror_obj['revision']).not_to be_nil
      expect(mirror_obj['branch']).to eq('master')
      expect(mirror_obj['tag']).to be_nil
      expect(mirror_obj['path']).to eq('lay outs')
    end
  end

  describe 'from a single file in a git repository' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny', :name => 'Some body', :email => 'somebody@example.com')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add --path layouts/layout.liquid #{@vendor_repository_dir} skit-layout.liquid")
      end
    end

    it 'should add the file and commit' do
      assert_no_diff("#{FIXTURE_PATH}/skit1/layouts/layout.liquid", "#{@repository_dir}/skit-layout.liquid")

      in_dir(@repository_dir) do
        assert_commit_subject(/Braid: Add mirror 'skit-layout.liquid' at '[0-9a-f]{7}'/)
        assert_commit_author('Some body')
        assert_commit_email('somebody@example.com')
      end
    end

    it 'should create .braids.json and add the mirror to it' do
      braids = YAML::load_file("#{@repository_dir}/.braids.json")
      expect(braids['config_version']).to be_kind_of(Numeric)
      mirror_obj = braids['mirrors']['skit-layout.liquid']
      expect(mirror_obj['url']).to eq(@vendor_repository_dir)
      expect(mirror_obj['revision']).not_to be_nil
      expect(mirror_obj['branch']).to eq('master')
      expect(mirror_obj['tag']).to be_nil
      expect(mirror_obj['path']).to eq('layouts/layout.liquid')
    end
  end

  describe 'from a tag in a git repository' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny', :name => 'Some body', :email => 'somebody@example.com')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')
      in_dir(@vendor_repository_dir) do
        run_command('git tag v1')
      end

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir} --tag v1")
      end
    end

    it 'should add the files and commit' do
      assert_no_diff("#{FIXTURE_PATH}/skit1/layouts/layout.liquid", "#{@repository_dir}/skit1/layouts/layout.liquid")

      in_dir(@repository_dir) do
        assert_commit_subject(/Braid: Add mirror 'skit1' at '[0-9a-f]{7}'/)
        assert_commit_author('Some body')
        assert_commit_email('somebody@example.com')
      end
    end

    it 'should create .braids.json and add the mirror to it' do
      braids = YAML::load_file("#{@repository_dir}/.braids.json")
      expect(braids['config_version']).to be_kind_of(Numeric)
      mirror_obj = braids['mirrors']['skit1']
      expect(mirror_obj['url']).to eq(@vendor_repository_dir)
      expect(mirror_obj['revision']).not_to be_nil
      expect(mirror_obj['branch']).to be_nil
      expect(mirror_obj['tag']).to eq('v1')
      expect(mirror_obj['path']).to be_nil
    end
  end

  describe 'from an annotated tag in a git repository' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny', :name => 'Some body', :email => 'somebody@example.com')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')
      in_dir(@vendor_repository_dir) do
        run_command('git tag -a -m "v1" v1')
      end

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir} --tag v1")
      end
    end

    it 'should add the files and commit' do
      assert_no_diff("#{FIXTURE_PATH}/skit1/layouts/layout.liquid", "#{@repository_dir}/skit1/layouts/layout.liquid")

      in_dir(@repository_dir) do
        assert_commit_subject(/Braid: Add mirror 'skit1' at '[0-9a-f]{7}'/)
        assert_commit_author('Some body')
        assert_commit_email('somebody@example.com')
      end
    end

    it 'should create .braids.json and add the mirror to it' do
      braids = YAML::load_file("#{@repository_dir}/.braids.json")
      expect(braids['config_version']).to be_kind_of(Numeric)
      mirror_obj = braids['mirrors']['skit1']
      expect(mirror_obj['url']).to eq(@vendor_repository_dir)
      expect(mirror_obj['revision']).not_to be_nil
      expect(mirror_obj['branch']).to be_nil
      expect(mirror_obj['tag']).to eq('v1')
      expect(mirror_obj['path']).to be_nil
    end
  end

  describe 'from a revision in a git repository' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny', :name => 'Some body', :email => 'somebody@example.com')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')
      in_dir(@vendor_repository_dir) do
        run_command('git tag v1')
        @revision = run_command('git rev-parse HEAD').strip
      end

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir} --revision #{@revision}")
      end
    end

    it 'should add the files and commit' do
      assert_no_diff("#{FIXTURE_PATH}/skit1/layouts/layout.liquid", "#{@repository_dir}/skit1/layouts/layout.liquid")

      in_dir(@repository_dir) do
        assert_commit_subject(/Braid: Add mirror 'skit1' at '[0-9a-f]{7}'/)
        assert_commit_author('Some body')
        assert_commit_email('somebody@example.com')
      end
    end

    it 'should create .braids.json and add the mirror to it' do
      braids = YAML::load_file("#{@repository_dir}/.braids.json")
      expect(braids['config_version']).to be_kind_of(Numeric)
      mirror_obj = braids['mirrors']['skit1']
      expect(mirror_obj['url']).to eq(@vendor_repository_dir)
      expect(mirror_obj['revision']).not_to be_nil
      expect(mirror_obj['branch']).to be_nil
      expect(mirror_obj['tag']).to be_nil
      expect(mirror_obj['path']).to be_nil
    end
  end

  describe 'with a git repository' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny', :name => 'Some body', :email => 'somebody@example.com')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')
      in_dir(@vendor_repository_dir) do
        run_command('git tag v1')
      end
    end

    it 'should generate an error if both tag and revision specified' do
      output = nil
      in_dir(@repository_dir) do
        output = `#{BRAID_BIN} add #{@vendor_repository_dir} --revision X --tag v1`
      end

      expect(output).to match(/^Braid: Error: Can not add mirror specifying both a revision and a tag$/)
    end

    it 'should generate an error if too many arguments are given' do
      output = nil
      in_dir(@repository_dir) do
        output = `#{BRAID_BIN} add #{@vendor_repository_dir} skit1 extra`
      end

      expect(output).to eq("Braid: Error: Extra argument(s) passed to command.\n")
    end
  end
end
