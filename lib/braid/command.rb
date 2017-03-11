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
      Command.run(:setup, mirror.path)
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

    def validate_new_revision(mirror, new_revision)
      return git.rev_parse(mirror.remote) unless new_revision

      new_revision = git.rev_parse(new_revision)
      old_revision = mirror.revision

      if new_revision == old_revision
        raise InvalidRevision, 'mirror is already at requested revision'
      end

      new_revision
    end

    def determine_target_revision(new_revision)
      git.rev_parse(new_revision)
    end
  end
end
