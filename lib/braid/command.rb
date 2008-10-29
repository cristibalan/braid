module Braid
  class Command
    class InvalidRevision < BraidError
    end

    extend Operations::VersionControl
    include Operations::VersionControl

    def self.run(command, *args)
      verify_git_version!

      klass = Commands.const_get(command.to_s.capitalize)
      klass.new.run(*args)

    rescue BraidError => error
      case error
      when Operations::ShellExecutionError
        msg "Shell error: #{error.message}"
      else
        msg "Error: #{error.message}"
      end
      exit(1)
    end

    def self.msg(str)
      puts "Braid: #{str}"
    end

    def msg(str)
      self.class.msg(str)
    end

    def config
      @config ||= load_and_migrate_config
    end

    def verbose?
      Braid.verbose
    end

    private
      def setup_remote(mirror)
        Command.run(:setup, mirror.path)
      end

      def use_local_cache?
        Braid.use_local_cache
      end

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

      def load_and_migrate_config
        config = Config.new
        unless config.valid?
          msg "Configuration is outdated. Migrating."
          bail_on_local_changes!
          config.migrate!
          git.commit("Upgrade .braids", "-- .braids")
        end
        config
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
          raise InvalidRevision, "mirror is already at requested revision"
        end

        if mirror.type == "svn"
          if old_revision && new_revision < old_revision
            raise InvalidRevision, "local revision is higher than request revision"
          end

          if svn.head_revision(mirror.url) < new_revision
            raise InvalidRevision, "requested revision is higher than remote revision"
          end
        end

        new_revision
      end

      def determine_target_revision(mirror, new_revision)
        unless mirror.type == "svn"
          git.rev_parse(new_revision)
        else
          git_svn.commit_hash(mirror.remote, new_revision)
        end
      end
  end
end
