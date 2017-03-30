require File.dirname(__FILE__) + '/integration_helper'

describe 'Running braid status on a mirror' do
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
      end
    end
    describe 'with no changes' do
      it 'should only emit version when neither modified' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} status skit1")
        end

        expect(diff).to match(/^skit1 \([0-9a-f]{40}\) \[BRANCH=master\]$/)
      end
    end

    describe 'with local changes' do
      it 'should emit local modified indicator' do
        output = nil
        in_dir(@repository_dir) do
          File.open("#{@repository_dir}/skit1/foo.txt", 'wb') { |f| f.write('Hi') }
          run_command('git add *')
          run_command('git commit -m "modify mirror"')
          output = run_command("#{BRAID_BIN} status skit1")
        end

        expect(output).to match(/^skit1 \([0-9a-f]{40}\) \[BRANCH=master\] \(Locally Modified\)$/)
      end
    end

    describe 'with remote changes' do
      it 'should emit remote modified indicator' do
        update_dir_from_fixture('skit1', 'skit1.1')
        in_dir(@vendor_repository_dir) do
          run_command('git add *')
          run_command('git commit -m "change default color"')
        end

        output = nil
        in_dir(@repository_dir) do
          output = run_command("#{BRAID_BIN} status skit1")
        end

        expect(output).to match(/^skit1 \([0-9a-f]{40}\) \[BRANCH=master\] \(Remote Modified\)$/)
      end
    end
  end

  describe 'braided into branch in' do
    before do
      in_dir(@vendor_repository_dir) do
        run_command('git checkout -bbranch1 2>&1')
      end
      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir} --branch branch1")
      end
    end
    describe 'with no changes' do
      it 'should only emit version when neither modified' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} status skit1")
        end

        expect(diff).to match(/^skit1 \([0-9a-f]{40}\) \[BRANCH=branch1\]$/)
      end
    end

    describe 'with local changes' do
      it 'should emit local modified indicator' do
        output = nil
        in_dir(@repository_dir) do
          File.open("#{@repository_dir}/skit1/foo.txt", 'wb') { |f| f.write('Hi') }
          run_command('git add *')
          run_command('git commit -m "modify mirror"')
          output = run_command("#{BRAID_BIN} status skit1")
        end

        expect(output).to match(/^skit1 \([0-9a-f]{40}\) \[BRANCH=branch1\] \(Locally Modified\)$/)
      end
    end

    describe 'with remote changes' do
      it 'should emit remote modified indicator' do
        update_dir_from_fixture('skit1', 'skit1.1')
        in_dir(@vendor_repository_dir) do
          run_command('git add *')
          run_command('git commit -m "change default color"')
        end

        output = nil
        in_dir(@repository_dir) do
          output = run_command("#{BRAID_BIN} status skit1")
        end

        expect(output).to match(/^skit1 \([0-9a-f]{40}\) \[BRANCH=branch1\] \(Remote Modified\)$/)
      end
    end
  end

  describe 'braided directly in as tag' do
    before do
      in_dir(@vendor_repository_dir) do
        run_command('git tag v1')
      end

      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir} --tag v1")
      end
    end
    describe 'with no changes' do
      it 'should only emit version when neither modified' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} status skit1")
        end

        expect(diff).to match(/^skit1 \([0-9a-f]{40}\) \[TAG=v1\]$/)
      end
    end

    describe 'with local changes' do
      it 'should emit local modified indicator' do
        output = nil
        in_dir(@repository_dir) do
          File.open("#{@repository_dir}/skit1/foo.txt", 'wb') { |f| f.write('Hi') }
          run_command('git add *')
          run_command('git commit -m "modify mirror"')
          output = run_command("#{BRAID_BIN} status skit1")
        end

        expect(output).to match(/^skit1 \([0-9a-f]{40}\) \[TAG=v1\] \(Locally Modified\)$/)
      end
    end

    describe 'with remote changes' do
      it 'should emit remote modified indicator' do
        update_dir_from_fixture('skit1', 'skit1.1')
        in_dir(@vendor_repository_dir) do
          run_command('git add *')
          run_command('git commit -m "change default color"')
          run_command('git tag -f v1')
        end

        output = nil
        in_dir(@repository_dir) do
          output = run_command("#{BRAID_BIN} status skit1")
        end

        expect(output).to match(/^skit1 \([0-9a-f]{40}\) \[TAG=v1\] \(Remote Modified\)$/)
      end
    end
  end
end
