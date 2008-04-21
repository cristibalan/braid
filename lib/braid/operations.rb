begin
  require 'rubygems'
rescue
end
require 'open4'

module Braid
  module Operations
    module Git
      def git_commit(message)
        exec!("git commit -m #{message.inspect} --no-verify")
        true
      end

      def git_fetch(remote)
        exec!("git fetch #{remote}")
        true
      end

      def git_checkout(treeish)
        # TODO debug
        msg "Checking out '#{treeish}'."
        exec!("git checkout #{treeish}")
        true
      end

      def git_merge_base(target, source)
        status, out, err = exec!("git merge-base #{target} #{source}")
        out.strip
      end

      def git_rev_parse(commit)
        status, out, err = exec!("git rev-parse #{commit}")
        out.strip
      end

      def git_remote_add(remote, path, branch)
        exec!("git remote add -f -t #{branch} -m #{branch} #{remote} #{path}")
        true
      end
    end

    module Svn
      def svn_remote_head_revision(path)
        # not using svn info because it's retarded and doesn't show the actual last changed rev for the url
        # git svn has no clue on how to get the actual HEAD revision number on it's own
        status, out, err = exec!("svn log -q --limit 1 #{path}")
        out.split(/\n/).find { |x| x.match /^r\d+/ }.split(" | ")[0][1..-1].to_i
      end

      def svn_git_commit_hash(remote, revision)
        status, out, err = exec!("git svn log --show-commit --oneline -r #{revision} #{remote}")
        invoke(:git_rev_parse, out.split(" | ")[1])
      end

      def git_svn_fetch(remote)
        exec!("git svn fetch #{remote}")
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
      rescue Braid::Commands::ShellExecutionError => e
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
        # TODO add checks for unlocked mirrors
        return unless new_revision = clean_svn_revision(new_revision)
        old_revision = clean_svn_revision(old_revision)

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
        local_branch = params["local_branch"]

        if options["revision"]
          if params["type"] == "svn"
            invoke(:svn_git_commit_hash, local_branch, options["revision"])
          else
            invoke(:git_rev_parse, options["revision"])
          end
        else
          invoke(:git_rev_parse, local_branch)
        end
      end
    end

    module Mirror
      def get_current_branch
        status, out, err = exec!("git branch | grep -e '\*'")
        out[2..-1]
      end

      def create_work_branch
        # check if branch exists
        status, out, err = exec("git branch | grep -e '#{TRACK_BRANCH}'")
        if status != 0
          # then create it
          msg "Creating work branch '#{TRACK_BRANCH}'."
          exec!("git branch #{TRACK_BRANCH}")
        end

        true
      end

      def get_work_head
        find_git_revision(TRACK_BRANCH)
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
        case type
        when "git"
          invoke(:git_fetch, remote)
        when "svn"
          invoke(:git_svn_fetch, remote)
        end
      end
    end

    extend Git
    extend Svn
    include Mirror
    include Helpers

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
