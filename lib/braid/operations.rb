# typed: strict

require 'singleton'
require 'rubygems'
require 'shellwords'
require 'tempfile'

module Braid
  require 'open3'

  module Operations
    class ShellExecutionError < BraidError
      sig {returns(String)}
      attr_reader :err, :out

      sig {params(err: String, out: String).void}
      def initialize(err, out)
        @err = err
        @out = out
      end

      sig {returns(String)}
      def message
        first_line = @err.to_s.split("\n").first
        # Currently, first_line can be nil if @err was empty, but Sorbet thinks
        # that the `message` method of an Exception should always return non-nil
        # (although override checking isn't enforced as of this writing), so
        # handle nil here.  This seems ad-hoc but better than putting in a
        # `T.must` that we know has a risk of being wrong.  Hopefully this will
        # be fixed better in https://github.com/cristibalan/braid/issues/90.
        first_line.nil? ? '' : first_line
      end
    end
    class VersionTooLow < BraidError
      sig {params(command: String, version: String, required: String).void}
      def initialize(command, version, required)
        @command  = command
        # TODO (typing): Probably should not be nilable
        @version  = T.let(version.to_s.split("\n").first, T.nilable(String))
        @required = required
      end

      sig {returns(String)}
      def message
        "#{@command} version too low: #{@version}. #{@required} needed."
      end
    end
    class UnknownRevision < BraidError
      sig {returns(String)}
      def message
        "unknown revision: #{super}"
      end
    end
    class LocalChangesPresent < BraidError
      sig {returns(String)}
      def message
        'local changes are present'
      end
    end
    class MergeError < BraidError
      sig {returns(String)}
      attr_reader :conflicts_text

      sig {params(conflicts_text: String).void}
      def initialize(conflicts_text)
        @conflicts_text = conflicts_text
      end

      sig {returns(String)}
      def message
        'could not merge'
      end
    end

    # The command proxy is meant to encapsulate commands such as git, that work with subcommands.
    class Proxy
      extend T::Sig
      include Singleton

      # TODO (typing): We could make this method abstract if our fake Sorbet
      # runtime supported abstract methods.
      sig {returns(String)}
      def self.command
        raise InternalError, 'Proxy.command not overridden'
      end

      # hax!
      sig {returns(String)}
      def version
        _, out, _ = exec!([self.class.command, '--version'])
        out.sub(/^.* version/, '').strip.sub(/ .*$/, '').strip
      end

      sig {params(required: String).returns(T::Boolean)}
      def require_version(required)
        # Gem::Version is intended for Ruby gem versions, but various web sites
        # suggest it as a convenient way of comparing version strings in
        # general.  None of the fine points of its semantics compared to those
        # of Git version numbers seem likely to cause a problem for Braid.
        Gem::Version.new(version) >= Gem::Version.new(required)
      end

      sig {params(required: String).void}
      def require_version!(required)
        require_version(required) || raise(VersionTooLow.new(self.class.command, version, required))
      end

      private

      sig {params(name: String).returns(T::Array[String])}
      def command(name)
        # stub
        [name]
      end

      sig {params(arg: String, args: T::Array[String]).returns(String)}
      def invoke(arg, args)
        exec!(command(arg) + args)[1].strip # return stdout
      end

      # Some of the unit tests want to mock out `exec`, but they have no way to
      # construct a real Process::Status and thus use an integer instead.  We
      # have to accommodate this in the type annotation to avoid runtime type
      # check failures during the tests.  In normal use of Braid, this will
      # always be a real Process::Status.  Fortunately, allowing Integer doesn't
      # seem to cause any other problems right now.
      ProcessStatusOrInteger = T.type_alias { T.any(Process::Status, Integer) }

      sig {params(cmd: T::Array[String]).returns([ProcessStatusOrInteger, String, String])}
      def exec(cmd)
        Operations::with_modified_environment({'LANG' => 'C'}) do
          log(cmd)
          # The special `[cmd[0], cmd[0]]` syntax ensures that `cmd[0]` is
          # interpreted as the path of the executable and not a shell command
          # even if `cmd` has only one element. See the documentation:
          # https://ruby-doc.org/core-3.1.2/Process.html#method-c-spawn.
          # Granted, this shouldn't matter for Braid for two reasons: (1)
          # `cmd[0]` is always "git", which doesn't contain any shell special
          # characters, and (2) `cmd` always has at least one additional
          # argument (the Git subcommand). However, it's still nice to make our
          # intent clear.
          out, err, status = T.unsafe(Open3).capture3([cmd[0], cmd[0]], *cmd[1..])
          [status, out, err]
        end
      end

      sig {params(cmd: T::Array[String]).returns([ProcessStatusOrInteger, String, String])}
      def exec!(cmd)
        status, out, err = exec(cmd)
        raise ShellExecutionError.new(err, out) unless status == 0
        [status, out, err]
      end

      sig {params(cmd: T::Array[String]).returns(ProcessStatusOrInteger)}
      def system(cmd)
        # Without this, "braid diff" output came out in the wrong order on Windows.
        $stdout.flush
        $stderr.flush
        Operations::with_modified_environment({'LANG' => 'C'}) do
          # See the comment in `exec` about the `[cmd[0], cmd[0]]` syntax.
          T.unsafe(Kernel).system([cmd[0], cmd[0]], *cmd[1..])
          return $?
        end
      end

      sig {params(str: String).void}
      def msg(str)
        puts "Braid: #{str}"
      end

      sig {params(cmd: T::Array[String]).void}
      def log(cmd)
        # Note: `Shellwords.shelljoin` follows Bourne shell quoting rules, as
        # its documentation states.  This may not be what a Windows user
        # expects, but it's not worth the trouble to try to find a library that
        # produces something better on Windows, especially because it's unclear
        # which of Windows's several different quoted formats we would use
        # (e.g., CommandLineToArgvW, cmd.exe, or PowerShell).  The most
        # important thing is to use _some_ unambiguous representation.
        msg "Executing `#{Shellwords.shelljoin(cmd)}` in #{Dir.pwd}" if verbose?
      end

      sig {returns(T::Boolean)}
      def verbose?
        Braid.verbose
      end
    end

    class Git < Proxy

      sig {returns(String)}
      def self.command
        'git'
      end

      # A string representing a Git object ID (i.e., hash).  This type alias is
      # used as documentation and is not enforced, so there's a risk that we
      # mistakenly mark something as an ObjectID when it can actually be a
      # String that is not an ObjectID.
      ObjectID = T.type_alias { String }

      # A string containing an expression that can be evaluated to an object ID
      # by `git rev-parse`.  Ditto the remark about lack of enforcement.
      ObjectExpr = T.type_alias { String } 

      # Get the physical path to a file in the git repository (e.g.,
      # 'MERGE_MSG'), taking into account worktree configuration.  The returned
      # path may be absolute or relative to the current working directory.
      sig {params(path: String).returns(String)}
      def repo_file_path(path)
        invoke('rev-parse', ['--git-path', path])
      end

      # If the current directory is not inside a git repository at all, this
      # command will fail with "fatal: Not a git repository" and that will be
      # propagated as a ShellExecutionError.  is_inside_worktree can return
      # false when inside a bare repository and in certain other rare cases such
      # as when the GIT_WORK_TREE environment variable is set.
      sig {returns(T::Boolean)}
      def is_inside_worktree
        invoke('rev-parse', ['--is-inside-work-tree']) == 'true'
      end

      # Get the prefix of the current directory relative to the worktree.  Empty
      # string if it's the root of the worktree, otherwise ends with a slash.
      # In some cases in which the current directory is not inside a worktree at
      # all, this will successfully return an empty string, so it may be
      # desirable to check is_inside_worktree first.
      sig {returns(String)}
      def relative_working_dir
        invoke('rev-parse', ['--show-prefix'])
      end

      sig {params(message: T.nilable(String), args: T::Array[String]).returns(T::Boolean)}
      def commit(message, args = [])
        cmd = ['git', 'commit', '--no-verify']
        message_file = nil
        if message # allow nil
          message_file = Tempfile.new('braid_commit')
          message_file.print("Braid: #{message}")
          message_file.flush
          message_file.close
          cmd += ['-F', T.must(message_file.path)]
        end
        cmd += args
        status, out, err = exec(cmd)
        message_file.unlink if message_file

        if status == 0
          true
        elsif out.match(/nothing.* to commit/)
          false
        else
          raise ShellExecutionError.new(err, out)
        end
      end

      sig {params(remote: T.nilable(String), args: T::Array[String]).void}
      def fetch(remote = nil, args = [])
        args = ['-n', remote] + args if remote
        exec!(['git', 'fetch'] + args)
      end

      # Returns the base commit or nil.
      sig {params(target: ObjectExpr, source: ObjectExpr).returns(T.nilable(ObjectID))}
      def merge_base(target, source)
        invoke('merge-base', [target, source])
      rescue ShellExecutionError
        nil
      end

      sig {params(expr: ObjectExpr).returns(ObjectID)}
      def rev_parse(expr)
        invoke('rev-parse', [expr])
      rescue ShellExecutionError
        raise UnknownRevision, expr
      end

      # Implies tracking.
      #
      # TODO (typing): Remove the return value if we're confident that nothing
      # uses it, here and in similar cases.
      sig {params(remote: String, path: String).returns(TrueClass)}
      def remote_add(remote, path)
        invoke('remote', ['add', remote, path])
        true
      end

      sig {params(remote: String).returns(TrueClass)}
      def remote_rm(remote)
        invoke('remote', ['rm', remote])
        true
      end

      # Checks git remotes.
      sig {params(remote: String).returns(T.nilable(String))}
      def remote_url(remote)
        key = "remote.#{remote}.url"
        invoke('config', [key])
      rescue ShellExecutionError
        nil
      end

      sig {params(target: ObjectExpr).returns(TrueClass)}
      def reset_hard(target)
        invoke('reset', ['--hard', target])
        true
      end

      # Merge three trees (local_treeish should match the current state of the
      # index) and update the index and working tree.
      #
      # The usage of 'git merge-recursive' doesn't seem to be officially
      # documented, but it does accept trees.  When a single base is passed, the
      # 'recursive' part (i.e., merge of bases) does not come into play and only
      # the trees matter.  But for some reason, Git's smartest tree merge
      # algorithm is only available via the 'recursive' strategy.
      sig {params(base_treeish: ObjectExpr, local_treeish: ObjectExpr, remote_treeish: ObjectExpr).returns(TrueClass)}
      def merge_trees(base_treeish, local_treeish, remote_treeish)
        invoke('merge-recursive', [base_treeish, '--', local_treeish, remote_treeish])
        true
      rescue ShellExecutionError => error
        # 'CONFLICT' messages go to stdout.
        raise MergeError, error.out
      end

      sig {params(prefix: String).returns(String)}
      def read_ls_files(prefix)
        invoke('ls-files', [prefix])
      end

      class BlobWithMode
        extend T::Sig
        sig {params(hash: ObjectID, mode: String).void}
        def initialize(hash, mode)
          @hash = hash
          @mode = mode
        end
        sig {returns(ObjectID)}
        attr_reader :hash
        sig {returns(String)}
        attr_reader :mode
      end
      # Allow the class to be referenced as `git.BlobWithMode`.
      sig {returns(T.class_of(BlobWithMode))}
      def BlobWithMode
        Git::BlobWithMode
      end
      # An ObjectID used as a TreeItem represents a tree.
      TreeItem = T.type_alias { T.any(ObjectID, BlobWithMode) }

      # Get the item at the given path in the given tree.  If it's a tree, just
      # return its hash; if it's a blob, return a BlobWithMode object.  (This is
      # how we remember the mode for single-file mirrors.)
      # TODO (typing): Should `path` be nilable?
      sig {params(tree: ObjectExpr, path: T.nilable(String)).returns(TreeItem)}
      def get_tree_item(tree, path)
        if path.nil? || path == ''
          tree
        else
          m = /^([^ ]*) ([^ ]*) ([^\t]*)\t.*$/.match(invoke('ls-tree', [tree, path]))
          if m.nil?
            # This can happen if the user runs `braid add` with a `--path` that
            # doesn't exist.  TODO: Make the error message more user-friendly in
            # that case.
            raise BraidError, 'No tree item exists at the given path'
          end
          mode = T.must(m[1])
          type = T.must(m[2])
          hash = T.must(m[3])
          if type == 'tree'
            hash
          elsif type == 'blob'
            return BlobWithMode.new(hash, mode)
          else
            raise BraidError, 'Tree item is not a tree or a blob'
          end
        end
      end

      # Add the item (as returned by get_tree_item) to the index at the given
      # path.  If update_worktree is true, then update the worktree, otherwise
      # disregard the state of the worktree (most useful with a temporary index
      # file).
      sig {params(item: TreeItem, path: String, update_worktree: T::Boolean).void}
      def add_item_to_index(item, path, update_worktree)
        if item.is_a?(BlobWithMode)
          invoke('update-index', ['--add', '--cacheinfo', "#{item.mode},#{item.hash},#{path}"])
          if update_worktree
            # XXX If this fails, we've already updated the index.
            invoke('checkout-index', [path])
          end
        else
          # According to
          # https://lore.kernel.org/git/e48a281a4d3db0a04c0609fcb8658e4fcc797210.1646166271.git.gitgitgadget@gmail.com/,
          # `--prefix=` is valid if the path is empty.
          invoke('read-tree', ["--prefix=#{path}", update_worktree ? '-u' : '-i', item])
        end
      end

      # Read tree into the root of the index.  This may not be the preferred way
      # to do it, but it seems to work.
      sig {params(treeish: ObjectExpr).void}
      def read_tree_im(treeish)
        invoke('read-tree', ['-im', treeish])
      end

      sig {params(treeish: ObjectExpr).void}
      def read_tree_um(treeish)
        invoke('read-tree', ['-um', treeish])
      end

      # Write a tree object for the current index and return its ID.
      sig {returns(ObjectID)}
      def write_tree
        invoke('write-tree', [])
      end

      # Execute a block using a temporary git index file, initially empty.
      sig {
        type_parameters(:R).params(
          blk: T.proc.returns(T.type_parameter(:R))
        ).returns(T.type_parameter(:R))
      }
      def with_temporary_index(&blk)
        Dir.mktmpdir('braid_index') do |dir|
          Operations::with_modified_environment(
            {'GIT_INDEX_FILE' => File.join(dir, 'index')}) do
            yield
          end
        end
      end

      sig {params(main_content: T.nilable(ObjectExpr), item_path: String, item: TreeItem).returns(ObjectID)}
      def make_tree_with_item(main_content, item_path, item)
        with_temporary_index do
          # If item_path is '', then rm_r_cached will fail.  But in that case,
          # we can skip loading the main content because it would be deleted
          # anyway.
          if main_content && item_path != ''
            read_tree_im(main_content)
            rm_r_cached(item_path)
          end
          add_item_to_index(item, item_path, false)
          write_tree
        end
      end

      sig {params(args: T::Array[String]).returns(T.nilable(String))}
      def config(args)
        invoke('config', args) rescue nil
      end

      sig {params(path: String).void}
      def add(path)
        invoke('add', [path])
      end

      sig {params(path: String).void}
      def rm(path)
        invoke('rm', [path])
      end

      sig {params(path: String).returns(TrueClass)}
      def rm_r(path)
        invoke('rm', ['-r', path])
        true
      end

      # Remove from index only.
      sig {params(path: String).returns(TrueClass)}
      def rm_r_cached(path)
        invoke('rm', ['-r', '--cached', path])
        true
      end

      sig {params(path: String, treeish: ObjectExpr).returns(ObjectID)}
      def tree_hash(path, treeish = 'HEAD')
        out = invoke('ls-tree', [treeish, '-d', path])
        T.must(out.split[2])
      end

      sig {params(args: T::Array[String]).returns(String)}
      def diff(args)
        invoke('diff', args)
      end

      sig {params(args: T::Array[String]).returns(ProcessStatusOrInteger)}
      def diff_to_stdout(args)
        # For now, ignore the exit code.  It can be 141 (SIGPIPE) if the user
        # quits the pager before reading all the output.
        system(['git', 'diff'] + args)
      end

      sig {returns(T::Boolean)}
      def status_clean?
        _, out, _ = exec(['git', 'status'])
        !out.split("\n").grep(/nothing to commit/).empty?
      end

      sig {void}
      def ensure_clean!
        status_clean? || raise(LocalChangesPresent)
      end

      sig {returns(ObjectID)}
      def head
        rev_parse('HEAD')
      end

      sig {void}
      def init
        invoke('init', [])
      end

      sig {params(args: T::Array[String]).void}
      def clone(args)
        invoke('clone', args)
      end

      # Wrappers for Git commands that were called via `method_missing` before
      # the move to static typing but for which the existing calls don't follow
      # a clear enough pattern around which we could design a narrower API than
      # forwarding an arbitrary argument list.  We may narrow the API in the
      # future if it becomes clear what it should be.

      sig {params(args: T::Array[String]).returns(String)}
      def rev_list(args)
        invoke('rev-list', args)
      end

      sig {params(args: T::Array[String]).void}
      def update_ref(args)
        invoke('update-ref', args)
      end

      sig {params(args: T::Array[String]).void}
      def push(args)
        invoke('push', args)
      end

      sig {params(args: T::Array[String]).returns(String)}
      def ls_remote(args)
        invoke('ls-remote', args)
      end

      private

      sig {params(name: String).returns(T::Array[String])}
      def command(name)
        [self.class.command, name]
      end
    end

    class GitCache
      extend T::Sig
      include Singleton

      sig {params(url: String).void}
      def fetch(url)
        dir = path(url)

        # remove local cache if it was created with --no-checkout
        if File.exist?("#{dir}/.git")
          FileUtils.rm_r(dir)
        end

        if File.exist?(dir)
          Dir.chdir(dir) do
            git.fetch
          end
        else
          FileUtils.mkdir_p(local_cache_dir)
          git.clone(['--mirror', url, dir])
        end
      end

      sig {params(url: String).returns(String)}
      def path(url)
        File.join(local_cache_dir, url.gsub(/[\/:@]/, '_'))
      end

      private

      sig {returns(String)}
      def local_cache_dir
        Braid.local_cache_dir
      end

      sig {returns(Git)}
      def git
        Git.instance
      end
    end

    module VersionControl
      extend T::Sig
      sig {returns(Git)}
      def git
        Git.instance
      end

      sig {returns(GitCache)}
      def git_cache
        GitCache.instance
      end
    end
  end
end
