require 'singleton'
require 'rubygems'
require 'tempfile'

module Braid
  USE_OPEN3 = defined?(JRUBY_VERSION) || Gem.win_platform?
  require USE_OPEN3 ? 'open3' : 'open4'

  module Operations
    class ShellExecutionError < BraidError
      attr_reader :err, :out

      def initialize(err = nil, out = nil)
        @err = err
        @out = out
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
        'local changes are present'
      end
    end
    class MergeError < BraidError
      attr_reader :conflicts_text

      def initialize(conflicts_text)
        @conflicts_text = conflicts_text
      end

      def message
        'could not merge'
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
        out.sub(/^.* version/, '').strip
      end

      def require_version(required)
        required = required.split('.')
        actual   = version.split('.')

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
            # Under old jrubies this may sometimes throw an exception
            stdin.close rescue nil
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
        raise ShellExecutionError.new(err, out) unless status == 0
        [status, out, err]
      end

      def msg(str)
        puts "Braid: #{str}"
      end

      def log(cmd)
        msg "Executing `#{cmd}` in #{Dir.pwd}" if verbose?
      end

      def verbose?
        Braid.verbose
      end
    end

    class Git < Proxy
      def commit(message, *args)
        cmd = 'git commit --no-verify'
        if message # allow nil
          message_file = Tempfile.new('braid_commit')
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
        exec!("git fetch #{args.join(' ')}")
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
        invoke(:remote, 'add', "-t #{branch} -m #{branch}", remote, path)
        true
      end

      def remote_rm(remote)
        invoke(:remote, 'rm', remote)
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
        invoke(:reset, '--hard', target)
        true
      end

      # Implies no commit.
      def merge_ours(opt)
        invoke(:merge, '--allow-unrelated-histories -s ours --no-commit', opt)
        true
      end

      # Implies no commit.
      def merge_subtree(opt)
        # TODO which options are needed?
        invoke(:merge, '-s subtree --no-commit --no-ff', opt)
        true
      rescue ShellExecutionError => error
        raise MergeError, error.out
      end

      # Merge three trees (local_treeish should match the current state of the
      # index) and update the index and working tree.
      #
      # The usage of 'git merge-recursive' doesn't seem to be officially
      # documented, but it does accept trees.  When a single base is passed, the
      # 'recursive' part (i.e., merge of bases) does not come into play and only
      # the trees matter.  But for some reason, Git's smartest tree merge
      # algorithm is only available via the 'recursive' strategy.
      def merge_trees(base_treeish, local_treeish, remote_treeish)
        invoke(:merge_recursive, base_treeish, "-- #{local_treeish} #{remote_treeish}")
        true
      rescue ShellExecutionError => error
        # 'CONFLICT' messages go to stdout.
        raise MergeError, error.out
      end

      def read_ls_files(prefix)
        invoke('ls-files', prefix)
      end

      # Read tree into the index and working tree.
      def read_tree_prefix_u(treeish, prefix)
        invoke(:read_tree, "--prefix=#{prefix}/ -u", treeish)
        true
      end

      # Read tree into the index, regardless of the state of the working tree.
      # Most useful with a temporary index file.
      def read_tree_prefix_i(treeish, prefix)
        invoke(:read_tree, "--prefix=#{prefix}/ -i", treeish)
        true
      end

      # Read tree into the root of the index.  This may not be the preferred way
      # to do it, but it seems to work.
      def read_tree_im(treeish)
        invoke(:read_tree, '-im', treeish)
        true
      end

      # Write a tree object for the current index and return its ID.
      def write_tree
        invoke(:write_tree)
      end

      # Execute a block using a temporary git index file, initially empty.
      def with_temporary_index
        Dir.mktmpdir('braid_index') do |dir|
          orig_index_file = ENV['GIT_INDEX_FILE']
          ENV['GIT_INDEX_FILE'] = File.join(dir, 'index')
          begin
            yield
          ensure
            ENV['GIT_INDEX_FILE'] = orig_index_file
          end
        end
      end

      def rm_r(path)
        invoke(:rm, '-r', path)
        true
      end

      # Remove from index only.
      def rm_r_cached(path)
        invoke(:rm, '-r', '--cached', path)
        true
      end

      def tree_hash(path, treeish = 'HEAD')
        out = invoke(:ls_tree, treeish, '-d', path)
        out.split[2]
      end

      def diff_tree(src_tree, dst_tree, prefix = nil)
        cmd = "git diff-tree -p --binary #{src_tree} #{dst_tree}"
        cmd << " --src-prefix=a/#{prefix}/ --dst-prefix=b/#{prefix}/" if prefix
        status, out, err = exec!(cmd)
        out
      end

      def status_clean?
        status, out, err = exec('git status')
        !out.split("\n").grep(/nothing to commit/).empty?
      end

      def ensure_clean!
        status_clean? || raise(LocalChangesPresent)
      end

      def head
        rev_parse('HEAD')
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
          git.clone('--mirror', url, dir)
        end
      end

      def path(url)
        File.join(local_cache_dir, url.gsub(/[\/:@]/, '_'))
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
