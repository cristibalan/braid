require_relative '../../lib/braid/check_gem'
require 'rubygems'
require 'rspec'
require 'mocha/api'

require 'tempfile'
require 'fileutils'
require 'pathname'

# Note: BRAID_USE_SORBET_RUNTIME affects any typed code in the integration test
# process (as of this writing, only `operations_lite`) as well as the Braid
# subprocesses that it spawns.
unless ENV['BRAID_USE_SORBET_RUNTIME']
  ENV['BRAID_USE_SORBET_RUNTIME'] = '1'
end

require File.dirname(__FILE__) + '/../../lib/braid/operations_lite'

DEFAULT_NAME = 'Your Name'
DEFAULT_EMAIL = 'you@example.com'

TMP_PATH = File.join(Dir.tmpdir, 'braid_integration')
EDITOR_CMD = "#{TMP_PATH}/editor"
BRAID_PATH = Pathname.new(File.dirname(__FILE__)).parent.parent.realpath
FIXTURE_PATH = File.join(BRAID_PATH, 'spec', 'fixtures')
FileUtils.rm_rf(TMP_PATH)
FileUtils.mkdir_p(TMP_PATH)

# It's OK to run `exe/braid` directly here because we checked that we're already
# running under Bundler.  That way, we avoid requiring the user to generate the
# `bin/braid` binstub if they don't want to.
BRAID_BIN = ((defined?(JRUBY_VERSION) || Gem.win_platform?) ? 'ruby ' : '') + File.join(BRAID_PATH, 'exe', 'braid')

# Use a separate, clean cache for each test case (because TMP_PATH is deleted
# and recreated for each test case).  We don't want to mess with the user's real
# cache, and this ensures that previous cache contents can't affect the behavior
# of the tests.
ENV['BRAID_LOCAL_CACHE_DIR'] = File.join(TMP_PATH, 'braid-cache')

# Must run in a git repository, though we expect the setting to be the same for
# most repositories on a given OS.
def filemode_enabled
  run_command('git config core.filemode').strip == 'true'
end

def with_editor_message(message = 'Make some changes')
  File.write(EDITOR_CMD, <<CMD)
#!/usr/bin/env ruby
File.open(ARGV[0], 'w') { |file| file.write(#{message.inspect}) }
CMD
  FileUtils.chmod 0755, EDITOR_CMD
  Braid::Operations::with_modified_environment({'GIT_EDITOR' => EDITOR_CMD}) do
    yield
  end
end

def assert_no_diff(file1, file2, extra_flags = '')
  run_command("diff -U 3 #{extra_flags} \"#{file1}\" \"#{file2}\"")
end

def assert_commit_attribute(format_key, value, commit_index = 0)
  output = run_command("git log --pretty=format:#{format_key}").split("\n")
  regex = value.is_a?(Regexp) ? value : /^#{value}$/
  expect(output[commit_index]).to match(regex)
end

def assert_commit_subject(value, commit_index = 0)
  assert_commit_attribute('%s', value, commit_index)
end

def assert_commit_author(value, commit_index = 0)
  assert_commit_attribute('%an', value, commit_index)
end

def assert_commit_email(value, commit_index = 0)
  assert_commit_attribute('%ae', value, commit_index)
end

def in_dir(dir = TMP_PATH)
  orig_wd = Dir.pwd
  Dir.chdir(dir)
  begin
    yield
  ensure
    Dir.chdir(orig_wd)
  end
end

# Note: Do not use single quotes to quote spaces in arguments.  They do not work
# on Windows.
def run_command(command)
  output = `#{command}`
  raise "Error executing command: #{command}\nOutput: #{output}" unless $?.success?
  output
end

def run_command_expect_failure(command)
  output = `#{command}`
  raise "Expected command to fail but it succeeded: #{command}\nOutput: #{output}" if $?.success?
  output
end

# Rough equivalent of git.require_version within Braid, but without pulling in a
# bunch of dependencies from Braid::Operations.  This small amount of code
# duplication seems like a lesser evil than sorting out all the dependencies.
def git_require_version(required)
  actual = run_command('git --version').sub(/^.* version/, '').strip.sub(/ .*$/, '').strip
  Gem::Version.new(actual) >= Gem::Version.new(required)
end

def update_dir_from_fixture(dir, fixture = dir)
  to_dir = File.join(TMP_PATH, dir)
  FileUtils.mkdir_p(to_dir)
  FileUtils.cp_r(File.join(FIXTURE_PATH, fixture) + '/.', to_dir, preserve: true)
end

def create_git_repo_from_fixture(fixture_name, options = {})
  directory = options[:directory] || fixture_name
  name = options[:name] || DEFAULT_NAME
  email = options[:email] || DEFAULT_EMAIL
  git_repo = File.join(TMP_PATH, directory)
  update_dir_from_fixture(directory, fixture_name)

  in_dir(git_repo) do
    # If we don't specify the initial branch name, Git >= 2.30 warns that the
    # default of `master` is subject to change.  We're still using `master` for
    # now, so avoid the warning by specifying it explicitly.  Git >= 2.28 honors
    # init.defaultBranch, while older versions of Git ignore it and are
    # hard-coded to use `master`.  (Using the `--initial-branch=master` option
    # would cause an error on Git < 2.28, so we don't do that.)
    run_command('git -c init.defaultBranch=master init')
    run_command("git config --local user.email \"#{email}\"")
    run_command("git config --local user.name \"#{name}\"")
    run_command('git config --local commit.gpgsign false')
    run_command('git add .')
    run_command("git commit -m \"initial commit of #{fixture_name}\"")
  end

  git_repo
end
