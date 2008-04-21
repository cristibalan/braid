module Braid
  class Command
    include Operations::Mirror
    include Operations::Helpers

    attr_accessor :config

    def initialize(options = {})
      @config = options["config"] || Braid::Config.new
    end

    def self.run(command, *args)
      klass = Braid::Commands.const_get(command.to_s.capitalize)
      klass.new.run_in_track_branch(*args)
    rescue => e
      # FIXME
    end

    def self.msg(str)
      puts str
    end

    def run_in_track_branch(*args)
      # make sure there is a git repository
      begin
        old_branch = get_current_branch
      rescue => e
        msg "Error occured: #{e}"
        raise e
      end

      create_work_branch
      work_head = get_work_head

      begin
        invoke(:git_checkout, TRACK_BRANCH)
        run(*args)
      rescue => e
        msg "Error occured: #{e}"
        if get_current_branch == TRACK_BRANCH
          msg "Resetting '#{TRACK_BRANCH}' to #{work_head}."
          exec!("git reset --hard #{work_head}")
        end
        raise e
      ensure
        invoke(:git_checkout, old_branch)
      end
    end

    private
      def msg(str)
        self.class.msg(str)
      end
  end
end

require 'braid/commands/add'
require 'braid/commands/remove'
require 'braid/commands/update'
require 'braid/commands/setup'
