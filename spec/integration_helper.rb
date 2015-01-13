require 'rubygems'
require 'rspec'
require 'mocha/api'

require 'tempfile'
require 'fileutils'
require 'pathname'

TMP_PATH     = File.join(Dir.tmpdir, "braid_integration")
BRAID_PATH   = Pathname.new(File.dirname(__FILE__)).parent.realpath
FIXTURE_PATH = File.join(BRAID_PATH, "spec", "fixtures")
FileUtils.rm_rf(TMP_PATH)
FileUtils.mkdir_p(TMP_PATH)

BRAID_BIN = ((defined?(JRUBY_VERSION) || Gem.win_platform?) ? 'ruby ' : '') + File.join(BRAID_PATH, 'bin', 'braid')

def in_dir(dir = TMP_PATH)
  Dir.chdir(dir)
  yield
end

def run_command(command)
  output = `#{command}`
  raise "Error executing command: #{command}\nOutput: #{output}" unless $?.success?
  output
end

def update_dir_from_fixture(dir, fixture = dir)
  to_dir = File.join(TMP_PATH, dir)
  FileUtils.mkdir_p(to_dir)
  FileUtils.cp_r(File.join(FIXTURE_PATH, fixture) + "/.", to_dir)
end

def create_git_repo_from_fixture(fixture_name)
  git_repo = File.join(TMP_PATH, fixture_name)
  update_dir_from_fixture(fixture_name)

  in_dir(git_repo) do
    run_command("git config --global --get user.email || git config --global user.email \"you@example.com\"")
    run_command("git config --global --get user.name  || git config --global user.name \"Your Name\"")
    run_command('git init')
    run_command('git add *')
    run_command("git commit -m \"initial commit of #{fixture_name}\"")
  end

  git_repo
end
