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
      @config ||= Config.new
    end

    def verbose?
      Braid.verbose
    end

    def force?
      Braid.force
    end

    private

    def setup_remote(mirror)
      existing_force = Braid.force
      begin
        Braid.force = true
        Command.run(:setup, mirror.path)
      ensure
        Braid.force = existing_force
      end
    end

    def clear_remote(mirror, options)
      git.remote_rm(mirror.remote) unless options['keep']
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
      bail_on_local_changes!

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
      git.rm(OLD_CONFIG_FILE) if File.exist?(OLD_CONFIG_FILE)
      git.add(CONFIG_FILE)
    end

    def display_revision(mirror, revision = nil)
      revision ||= mirror.revision
      "'#{revision[0, 7]}'"
    end

    def determine_repository_revision(mirror)
      if mirror.tag
        if use_local_cache?
          Dir.chdir git_cache.path(mirror.url) do
            git.rev_parse(mirror.local_ref)
          end
        else
          raise BraidError, 'unable to retrieve tag version when cache disabled.'
        end
      else
        git.rev_parse(mirror.local_ref)
      end
    end

    def validate_new_revision(mirror, revision)
      if revision.nil?
        determine_repository_revision(mirror)
      else
        new_revision = git.rev_parse(revision)

        if new_revision == mirror.revision
          raise InvalidRevision, 'mirror is already at requested revision'
        end

        new_revision
      end
    end

    def determine_target_revision(mirror, new_revision)
      git.rev_parse(mirror.versioned_path(new_revision))
    end
  end
end
