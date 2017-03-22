require 'rubygems'
require 'rspec'
require 'mocha/api'

require 'tempfile'
require 'fileutils'
require 'pathname'

DEFAULT_NAME = 'Your Name'
DEFAULT_EMAIL = 'you@example.com'

TMP_PATH = File.join(Dir.tmpdir, 'braid_integration')
EDITOR_CMD = "#{TMP_PATH}/editor"
EDITOR_CMD_PREFIX = "export GIT_EDITOR=#{EDITOR_CMD};"
BRAID_PATH = Pathname.new(File.dirname(__FILE__)).parent.realpath
FIXTURE_PATH = File.join(BRAID_PATH, 'spec', 'fixtures')
FileUtils.rm_rf(TMP_PATH)
FileUtils.mkdir_p(TMP_PATH)

BRAID_BIN = ((defined?(JRUBY_VERSION) || Gem.win_platform?) ? 'ruby ' : '') + File.join(BRAID_PATH, 'bin', 'braid')

def set_editor_message(message = 'Make some changes')
  File.write(EDITOR_CMD, <<CMD)
#!/usr/bin/env ruby
File.open(ARGV[0], 'w') { |file| file.write(#{message.inspect}) }
CMD
  FileUtils.chmod 0755, EDITOR_CMD
end

def assert_no_diff(file1, file2)
  run_command("diff -U 3 #{file1} #{file2}")
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
  FileUtils.cp_r(File.join(FIXTURE_PATH, fixture) + '/.', to_dir)
end

def create_git_repo_from_fixture(fixture_name, options = {})
  directory = options[:directory] || fixture_name
  name = options[:name] || DEFAULT_NAME
  email = options[:email] || DEFAULT_EMAIL
  git_repo = File.join(TMP_PATH, directory)
  update_dir_from_fixture(directory, fixture_name)

  in_dir(git_repo) do
    run_command('git init')
    run_command("git config --local user.email \"#{email}\"")
    run_command("git config --local user.name \"#{name}\"")
    run_command('git add *')
    run_command("git commit -m \"initial commit of #{fixture_name}\"")
  end

  git_repo
end
