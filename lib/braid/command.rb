module Braid
  class Command
    include Operations::Mirror
    include Operations::Helpers

    def self.run(command, *args)
      klass = Braid::Commands.const_get(command.to_s.capitalize)
      klass.new.run(*args)
    rescue => e
      # FIXME
    end

    def self.msg(str)
      puts str
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
