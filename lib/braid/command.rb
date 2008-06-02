module Braid
  class Command
    include Operations::Mirror
    include Operations::Helpers

    class << self
      include Operations::Helpers
      include Operations::Git

      def run(command, *args)
        raise Braid::Git::GitVersionTooLow    unless verify_version("git",     REQUIRED_GIT_VERSION)
        raise Braid::Git::GitSvnVersionTooLow unless verify_version("git svn", REQUIRED_GIT_SVN_VERSION)

        klass = Braid::Commands.const_get(command.to_s.capitalize)
        klass.new.run(*args)

      rescue Braid::Git::LocalChangesPresent => e
        msg "Local changes are present. You have to commit or stash them before running braid commands."
        msg "Exiting."

      rescue Braid::Git::GitVersionTooLow => e
        msg "This version of braid requires at least git #{REQUIRED_GIT_VERSION}. You have #{extract_version("git")}."
        msg "Exiting."

      rescue Braid::Git::GitSvnVersionTooLow => e
        msg "This version of braid requires at least git svn #{REQUIRED_GIT_SVN_VERSION}. You have #{extract_version("git svn")}."
        msg "Exiting."

      rescue => e
        puts "braid error: " + e.message
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

      def with_reset_on_error
        work_head = get_work_head

        begin
          yield
        rescue => e
          msg "Resetting to '#{work_head}'."
          invoke(:git_reset_hard, work_head)
          raise e
        end
      end
  end
end
