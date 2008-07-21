module Braid
  class Command
    class LocalRevisionIsHigherThanRequestedRevision < BraidError
    end
    class RequestedRevisionIsHigherThanRemoteRevision < BraidError
    end
    class MirrorAlreadyAtRequestedRevision < BraidError
    end

    extend Operations::VersionControl
    include Operations::VersionControl

    def self.run(command, *args)
      verify_git_version!

      klass = Commands.const_get(command.to_s.capitalize)
      klass.new.run(*args)

    rescue Operations::VersionTooLow => error
      msg "Error: git version too low: #{error.message}"
      exit(1)

    rescue Operations::LocalChangesPresent => error
      msg "Error: local changes are present, commit or stash them before running #{command}"
      exit(1)
    end

    def self.msg(str)
      puts str
    end

    def msg(str)
      self.class.msg(str)
    end

    def config
      @config ||= Config.new
    end

    private
      def self.verify_git_version!
        git.require_version!(REQUIRED_GIT_VERSION)
      end

      def bail_on_local_changes!
        git.ensure_clean!
      end

      def with_reset_on_error
        work_head = git.head

        begin
          yield
        rescue => error
          msg "Resetting to '#{work_head[0, 7]}'."
          git.reset_hard(work_head)
          raise error
        end
      end

      def add_config_file
        git.add(CONFIG_FILE)
      end

      def display_revision(mirror, revision = nil)
        revision ||= mirror.revision
        mirror.type == "svn" ? "r#{revision}" : "'#{revision[0, 7]}'"
      end

      def validate_new_revision(mirror, new_revision)
        unless new_revision
          unless mirror.type == "svn"
            return git.rev_parse(mirror.remote)
          else
            return svn.head_revision(mirror.url)
          end
        end

        unless mirror.type == "svn"
          new_revision = git.rev_parse(new_revision)
        else
          new_revision = svn.clean_revision(new_revision)
        end
        old_revision = mirror.revision

        if new_revision == old_revision
          raise MirrorAlreadyAtRequestedRevision
        end

        if mirror.type == "svn"
          if old_revision && new_revision < old_revision
            raise LocalRevisionIsHigherThanRequestedRevision
          end

          if svn.head_revision(mirror.url) < new_revision
            raise RequestedRevisionIsHigherThanRemoteRevision
          end
        end

        new_revision
      end

      def determine_target_commit(mirror, new_revision)
        unless mirror.type == "svn"
          git.rev_parse(new_revision)
        else
          git_svn.commit_hash(mirror.remote, new_revision)
        end
      end
  end
end
