module Braid
  module Operations
    module Git
      def git_commit(message)
        status, out, err = exec("git commit -m #{message.inspect} --no-verify")

        if status == 0
          true
        elsif out.match("nothing to commit")
          false
        else
          raise Braid::Commands::ShellExecutionError, err
        end
      end

      def git_fetch(remote)
        # open4 messes with the pipes of index-pack
        system("git fetch -n #{remote} &> /dev/null")
        raise Braid::Commands::ShellExecutionError unless $? == 0
        true
      end

      def git_checkout(treeish)
        # TODO debug
        msg "Checking out '#{treeish}'."
        exec!("git checkout #{treeish}")
        true
      end

      # Returns the base commit or nil.
      def git_merge_base(target, source)
        status, out, err = exec!("git merge-base #{target} #{source}")
        out.strip
      rescue Braid::Commands::ShellExecutionError
        nil
      end

      def git_rev_parse(commit)
        status, out, err = exec!("git rev-parse #{commit}")
        out.strip
      end

      # Implies tracking.
      def git_remote_add(remote, path, branch)
        exec!("git remote add -t #{branch} -m #{branch} #{remote} #{path}")
        true
      end

      def git_reset_hard(target)
        exec!("git reset --hard #{target}")
        true
      end

      # Implies no commit.
      def git_merge_ours(commit)
        exec!("git merge -s ours --no-commit #{commit}")
        true
      end

      # Implies no commit.
      def git_merge_subtree(commit)
        # TODO which options are needed?
        exec!("git merge -s subtree --no-commit --no-ff #{commit}")
        true
      end

      def git_read_tree(treeish, prefix)
        exec!("git read-tree --prefix=#{prefix}/ -u #{treeish}")
        true
      end

      def git_rm_r(path)
        exec!("git rm -r #{path}")
        true
      end
    end

    module Svn
      # FIXME move
      def svn_remote_head_revision(path)
        # not using svn info because it's retarded and doesn't show the actual last changed rev for the url
        # git svn has no clue on how to get the actual HEAD revision number on it's own
        status, out, err = exec!("svn log -q --limit 1 #{path}")
        out.split(/\n/).find { |x| x.match /^r\d+/ }.split(" | ")[0][1..-1].to_i
      end

      # FIXME move
      def svn_git_commit_hash(remote, revision)
        status, out, err = exec!("git svn log --show-commit --oneline -r #{revision} #{remote}")
        part = out.split(" | ")[1]
        raise Braid::Svn::UnknownRevision, "unknown revision: #{revision}" unless part
        invoke(:git_rev_parse, part)
      end

      def git_svn_fetch(remote)
        exec!("git svn fetch #{remote}")
        true
      end

      def git_svn_init(remote, path)
        exec!("git svn init -R #{remote} --id=#{remote} #{path}")
        true
      end
    end

    module Helpers
      [:invoke, :exec, :exec!].each do |method|
        define_method(method) do |*args|
          Braid::Operations.send(method, *args)
        end
      end

      def find_git_revision(commit)
        invoke(:git_rev_parse, commit)
      rescue Braid::Commands::ShellExecutionError
        raise Braid::Git::UnknownRevision, "unknown revision: #{commit}"
      end

      def clean_svn_revision(revision)
        if revision
          revision.to_i
        else
          nil
        end
      end

      def validate_svn_revision(old_revision, new_revision, path)
        return unless new_revision = clean_svn_revision(new_revision)
        old_revision = clean_svn_revision(old_revision)

        # TODO add checks for unlocked mirrors
        if old_revision
          if new_revision < old_revision
            raise Braid::Commands::LocalRevisionIsHigherThanRequestedRevision
          elsif new_revision == old_revision
            raise Braid::Commands::MirrorAlreadyUpToDate
          end
        end

        if path && invoke(:svn_remote_head_revision, path) < new_revision
          raise Braid::Commands::RequestedRevisionIsHigherThanRemoteRevision
        end

        true
      end

      # Make sure the revision is valid, then clean it.
      def validate_revision_option(params, options)
        if options["revision"]
          case params["type"]
          when "git"
            options["revision"] = find_git_revision(options["revision"])
          when "svn"
            validate_svn_revision(params["revision"], options["revision"], params["remote"])
            options["revision"] = clean_svn_revision(options["revision"])
          end
        end

        true
      end

      def determine_target_commit(params, options)
        if options["revision"]
          if params["type"] == "svn"
            invoke(:svn_git_commit_hash, params["local_branch"], options["revision"])
          else
            invoke(:git_rev_parse, options["revision"])
          end
        else
          invoke(:git_rev_parse, params["local_branch"])
        end
      end

      def display_revision(type, revision)
        type == "svn" ? "r#{revision}" : "'#{revision[0, 7]}'"
      end
    end

    module Mirror
      def get_current_branch
        status, out, err = exec!("git branch | grep '*'")
        out[2..-1]
      end

      def create_work_branch
        # check if branch exists
        status, out, err = exec("git branch | grep '#{WORK_BRANCH}'")
        if status != 0
          # then create it
          msg "Creating work branch '#{WORK_BRANCH}'."
          exec!("git branch #{WORK_BRANCH}")
        end

        true
      end

      def get_work_head
        find_git_revision(WORK_BRANCH)
      end

      def add_config_file
        exec!("git add #{CONFIG_FILE}")
        true
      end

      def check_merge_status(commit)
        commit = find_git_revision(commit)
        # tip from spearce in #git:
        # `test z$(git merge-base A B) = z$(git rev-parse --verify A)`
        if invoke(:git_merge_base, commit, "HEAD") == commit
          raise Braid::Commands::MirrorAlreadyUpToDate
        end

        true
      end

      def fetch_remote(type, remote)
        msg "Fetching data from '#{remote}'."
        case type
        when "git"
          invoke(:git_fetch, remote)
        when "svn"
          invoke(:git_svn_fetch, remote)
        end
      end

      def find_remote(remote)
        # TODO clean up and maybe return more information
        !!File.readlines(".git/config").find { |line| line =~ /^\[(svn-)?remote "#{remote}"\]/ }
      end
    end

    extend Git
    extend Svn

    def self.invoke(*args)
      send(*args)
    end

    def self.exec(cmd)
      #puts cmd
      out = ""
      err = ""
      cmd.strip!

      ENV['LANG'] = 'C' unless ENV['LANG'] == 'C'
      status = Open4::popen4(cmd) do |pid, stdin, stdout, stderr|
        out = stdout.read.strip
        err = stderr.read.strip
      end
      [status.exitstatus, out, err]
    end

    def self.exec!(cmd)
      status, out, err = exec(cmd)
      raise Braid::Commands::ShellExecutionError, err unless status == 0
      return status, out, err
    end

    private
      def self.msg(str)
        Braid::Command.msg(str)
      end
  end
end
