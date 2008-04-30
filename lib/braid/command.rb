module Braid
  class Command
    include Operations::Mirror
    include Operations::Helpers

    class << self
      include Operations::Helpers
      include Operations::Git

      def run(command, *args)
        raise Braid::Git::VersionTooLow unless verify_git_version(REQUIRED_GIT_VERSION)
        raise Braid::Git::LocalChangesPresent if local_changes?

        klass = Braid::Commands.const_get(command.to_s.capitalize)
        klass.new.run(*args)

      rescue Braid::Git::LocalChangesPresent => e
        msg "Local changes are present. You have to commit or stash them before running braid commands."

      rescue Braid::Git::VersionTooLow => e
        msg "This version of braid requires at least git #{REQUIRED_GIT_VERSION}. You have #{extract_git_version}."
        msg "Exiting."

      rescue => e
        # FIXME
      end

      def msg(str)
        puts str
      end
    end

    def config
      @config ||= Braid::Config.new
    end

    private
      def msg(str)
        self.class.msg(str)
      end

      def in_work_branch
        # make sure there is a git repository
        begin
          old_branch = get_current_branch
        rescue => e
          msg "Error occured: #{e.message}"
          raise e
        end

        create_work_branch
        work_head = get_work_head

        begin
          invoke(:git_checkout, WORK_BRANCH)
          yield
        rescue => e
          msg "Error occured: #{e.message}"
          if get_current_branch == WORK_BRANCH
            msg "Resetting '#{WORK_BRANCH}' to '#{work_head}'."
            invoke(:git_reset_hard, work_head)
          end
          raise e
        ensure
          invoke(:git_checkout, old_branch)
        end
      end
  end
end
