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

      assert_commit_subject(/Braid: Add mirror 'skit1' at '[0-9a-f]{7}'/)
      assert_commit_author('Some body')
      assert_commit_email('somebody@example.com')
    end

    it 'should create .braids.json and add the mirror to it' do
      braids = YAML::load_file("#{@repository_dir}/.braids.json")
      expect(braids['skit1']['url']).to eq(@vendor_repository_dir)
      expect(braids['skit1']['revision']).not_to be_nil
      expect(braids['skit1']['branch']).to eq('master')
      expect(braids['skit1']['tag']).to be_nil
      expect(braids['skit1']['path']).to be_nil
    end
  end

  describe 'from a subdirectory in a git repository' do
    before do
      @repository_dir = create_git_repo_from_fixture('shiny', :name => 'Some body', :email => 'somebody@example.com')
      @vendor_repository_dir = create_git_repo_from_fixture('skit1')

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add --path layouts #{@vendor_repository_dir}")
      end
    end

    it 'should add the files and commit' do
      assert_no_diff("#{FIXTURE_PATH}/skit1/layouts/layout.liquid", "#{@repository_dir}/skit1/layout.liquid")

      assert_commit_subject(/Braid: Add mirror 'skit1' at '[0-9a-f]{7}'/)
      assert_commit_author('Some body')
      assert_commit_email('somebody@example.com')
    end

    it 'should create .braids.json and add the mirror to it' do
      braids = YAML::load_file("#{@repository_dir}/.braids.json")
      expect(braids['skit1']['url']).to eq(@vendor_repository_dir)
      expect(braids['skit1']['revision']).not_to be_nil
      expect(braids['skit1']['branch']).to eq('master')
      expect(braids['skit1']['tag']).to be_nil
      expect(braids['skit1']['path']).to eq('layouts')
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

      assert_commit_subject(/Braid: Add mirror 'skit1' at '[0-9a-f]{7}'/)
      assert_commit_author('Some body')
      assert_commit_email('somebody@example.com')
    end

    it 'should create .braids.json and add the mirror to it' do
      braids = YAML::load_file("#{@repository_dir}/.braids.json")
      expect(braids['skit1']['url']).to eq(@vendor_repository_dir)
      expect(braids['skit1']['revision']).not_to be_nil
      expect(braids['skit1']['branch']).to be_nil
      expect(braids['skit1']['tag']).to eq('v1')
      expect(braids['skit1']['path']).to be_nil
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

      assert_commit_subject(/Braid: Add mirror 'skit1' at '[0-9a-f]{7}'/)
      assert_commit_author('Some body')
      assert_commit_email('somebody@example.com')
    end

    it 'should create .braids.json and add the mirror to it' do
      braids = YAML::load_file("#{@repository_dir}/.braids.json")
      expect(braids['skit1']['url']).to eq(@vendor_repository_dir)
      expect(braids['skit1']['revision']).not_to be_nil
      expect(braids['skit1']['branch']).to be_nil
      expect(braids['skit1']['tag']).to be_nil
      expect(braids['skit1']['path']).to be_nil
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
  end
end
