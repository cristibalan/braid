require 'singleton'
require 'rubygems'
require 'tempfile'

module Braid
  USE_OPEN3 = defined?(JRUBY_VERSION) || Gem.win_platform?
  require USE_OPEN3 ? 'open3' : 'open4'

  module Operations
    class ShellExecutionError < BraidError
      def initialize(err = nil)
        @err = err
      end

      def message
        @err.to_s.split("\n").first
      end
    end
    class VersionTooLow < BraidError
      def initialize(command, version, required)
        @command  = command
        @version  = version.to_s.split("\n").first
        @required = required
      end

      def message
        "#{@command} version too low: #{@version}. #{@required} needed."
      end
    end
    class UnknownRevision < BraidError
      def message
        "unknown revision: #{super}"
      end
    end
    class LocalChangesPresent < BraidError
      def message
        "local changes are present"
      end
    end
    class MergeError < BraidError
      def message
        "could not merge"
      end
    end

    # The command proxy is meant to encapsulate commands such as git, that work with subcommands.
    class Proxy
      include Singleton

      def self.command;
        name.split('::').last.downcase;
      end

      # hax!
      def version
        status, out, err = exec!("#{self.class.command} --version")
        out.sub(/^.* version/, "").strip
      end

      def require_version(required)
        required = required.split(".")
        actual   = version.split(".")

        actual.each_with_index do |actual_piece, idx|
          required_piece = required[idx]

          return true unless required_piece

          case (actual_piece <=> required_piece)
            when -1
              return false
            when 1
              return true
            when 0
              next
          end
        end

        return actual.length >= required.length
      end

      def require_version!(required)
        require_version(required) || raise(VersionTooLow.new(self.class.command, version, required))
      end

      private

      def command(name)
        # stub
        name
      end

      def invoke(arg, *args)
        exec!("#{command(arg)} #{args.join(' ')}".strip)[1].strip # return stdout
      end

      def method_missing(name, *args)
        invoke(name, *args)
      end

      def exec(cmd)
        cmd.strip!

        previous_lang = ENV['LANG']
        ENV['LANG']   = 'C'

        out, err = nil
        status, pid = 0
        log(cmd)

        if USE_OPEN3
          status = nil
          Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thread|
            stdin.close
            out = stdout.read
            err = stderr.read
            # Under earlier jrubies this is not correctly passed so add in check
            status = wait_thread.value if wait_thread # Process::Status object returned.
          end
          # Handle earlier jrubies such as 1.6.7.2
          status = $?.exitstatus if status.nil?
        else
          status = Open4.popen4(cmd) do |pid, stdin, stdout, stderr|
            out = stdout.read
            err = stderr.read
          end.exitstatus
        end

        [status, out, err]
      ensure
        ENV['LANG'] = previous_lang
      end

      def exec!(cmd)
        status, out, err = exec(cmd)
        raise ShellExecutionError, err unless status == 0
        [status, out, err]
      end

      def sh(cmd, message = nil)
        message ||= "could not fetch" if cmd =~ /fetch/
        log(cmd)
        `#{cmd}`
        raise ShellExecutionError, message unless $?.exitstatus == 0
        true
      end

      def msg(str)
        puts "Braid: #{str}"
      end

      def log(cmd)
        msg "Executing `#{cmd}`" if verbose?
      end

      def verbose?
        Braid.verbose
      end
    end

    class Git < Proxy
      def commit(message, *args)
        cmd = "git commit --no-verify"
        if message # allow nil
          message_file = Tempfile.new("braid_commit")
          message_file.print("Braid: #{message}")
          message_file.flush
          message_file.close
          cmd << " -F #{message_file.path}"
        end
        cmd << " #{args.join(' ')}" unless args.empty?
        status, out, err = exec(cmd)
        message_file.unlink if message_file

        if status == 0
          true
        elsif out.match(/nothing.* to commit/)
          false
        else
          raise ShellExecutionError, err
        end
      end

      def fetch(remote = nil, *args)
        args.unshift "-n #{remote}" if remote
        # open4 messes with the pipes of index-pack
        sh("git fetch #{args.join(' ')} 2>&1 > #{Gem.win_platform? ? 'nul' : '/dev/null'}")
      end

      def checkout(treeish)
        invoke(:checkout, treeish)
        true
      end

      # Returns the base commit or nil.
      def merge_base(target, source)
        invoke(:merge_base, target, source)
      rescue ShellExecutionError
        nil
      end

      def rev_parse(opt)
        invoke(:rev_parse, opt)
      rescue ShellExecutionError
        raise UnknownRevision, opt
      end

      # Implies tracking.
      def remote_add(remote, path, branch)
        invoke(:remote, "add", "-t #{branch} -m #{branch}", remote, path)
        true
      end

      def remote_rm(remote)
        invoke(:remote, "rm", remote)
        true
      end

      # Checks git remotes.
      def remote_url(remote)
        key = "remote.#{remote}.url"
        invoke(:config, key)
      rescue ShellExecutionError
        nil
      end

      def reset_hard(target)
        invoke(:reset, "--hard", target)
        true
      end

      # Implies no commit.
      def merge_ours(opt)
        invoke(:merge, "-s ours --no-commit", opt)
        true
      end

      # Implies no commit.
      def merge_subtree(opt)
        # TODO which options are needed?
        invoke(:merge, "-s subtree --no-commit --no-ff", opt)
        true
      rescue ShellExecutionError
        raise MergeError
      end

      def merge_recursive(base_hash, local_hash, remote_hash)
        invoke(:merge_recursive, base_hash, "-- #{local_hash} #{remote_hash}")
        true
      rescue ShellExecutionError
        raise MergeError
      end

      def read_ls_files(prefix)
        invoke('ls-files', prefix)
      end

      def read_tree_prefix(treeish, prefix)
        invoke(:read_tree, "--prefix=#{prefix}/ -u", treeish)
        true
      end

      def rm_r(path)
        invoke(:rm, "-r", path)
        true
      end

      def tree_hash(path, treeish = "HEAD")
        out = invoke(:ls_tree, treeish, "-d", path)
        out.split[2]
      end

      def diff_tree(src_tree, dst_tree, prefix = nil)
        cmd = "git diff-tree -p --binary #{src_tree} #{dst_tree}"
        cmd << " --src-prefix=a/#{prefix}/ --dst-prefix=b/#{prefix}/" if prefix
        status, out, err = exec!(cmd)
        out
      end

      def status_clean?
        status, out, err = exec("git status")
        !out.split("\n").grep(/nothing to commit/).empty?
      end

      def ensure_clean!
        status_clean? || raise(LocalChangesPresent)
      end

      def head
        rev_parse("HEAD")
      end

      def branch
        status, out, err = exec!("git branch | grep '*'")
        out[2..-1]
      end

      def apply(diff, *args)
        status, err = nil, nil

        command = "git apply --index --whitespace=nowarn #{args.join(' ')} -"

        if USE_OPEN3
          Open3.popen3(command) do |stdin, stdout, stderr, wait_thread|
            stdin.puts(diff)
            stdin.close
            err = stderr.read
            # Under earlier jrubies this is not correctly passed so add in check
            status = wait_thread.value if wait_thread # Process::Status object returned.
          end
          # Handle earlier jrubies such as 1.6.7.2
          status = $?.exitstatus if status.nil?
        else
          status = Open4.popen4(command) do |pid, stdin, stdout, stderr|
            stdin.puts(diff)
            stdin.close
            err = stderr.read
          end.exitstatus
        end

        raise ShellExecutionError, err unless status == 0
        true
      end

      def clone(*args)
        # overrides builtin
        invoke(:clone, *args)
      end

      private

      def command(name)
        "#{self.class.command} #{name.to_s.gsub('_', '-')}"
      end
    end

    class GitCache
      include Singleton

      def fetch(url)
        dir = path(url)

        # remove local cache if it was created with --no-checkout
        if File.exists?("#{dir}/.git")
          FileUtils.rm_r(dir)
        end

        if File.exists?(dir)
          Dir.chdir(dir) do
            git.fetch
          end
        else
          FileUtils.mkdir_p(local_cache_dir)
          git.clone("--mirror", url, dir)
        end
      end

      def path(url)
        File.join(local_cache_dir, url.gsub(/[\/:@]/, "_"))
      end

      private

      def local_cache_dir
        Braid.local_cache_dir
      end

      def git
        Git.instance
      end
    end

    module VersionControl
      def git
        Git.instance
      end

      def git_cache
        GitCache.instance
      end
    end
  end
end
