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
BRAID_BIN = File.join(BRAID_PATH, "bin", "braid")

#def exec(cmd)
#  `cd #{TMP} && #{cmd}`
#end

def in_dir(dir = TMP_PATH)
  Dir.chdir(dir)
  yield
end

def run_cmds(ary)
  ary.each do |cmd|
    cmd = cmd.strip!
    out = `#{cmd}`
  end
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
    run_cmds(<<-EOD)
      git init
      git add *
      git commit -m "initial commit of #{fixture_name}"
    EOD
  end

  git_repo
end
