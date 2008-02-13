require 'rubygems'
require 'open4'

module Braid
  class Command

    TRACK_BRANCH = "braid/track"

    attr_accessor :config, :cli

    def initialize(options = {})
      @config = options["config"] || Braid::Config.new
      #@cli = options["cli"] || Braid::Cli.new
    end

    def self.run(command, *args)
      klass = Braid::Commands.const_get(command.to_s.capitalize)
      klass.new.run_in_track_branch(*args)
    rescue Braid::Exception => e
      puts "braid: An exception has occured: #{e.message || e} (#{e})"
    end

    def run_in_track_branch(*args)
      current = get_current_branch

      create_work_branch
      work_head = get_work_head

      begin
        exec! "git checkout #{TRACK_BRANCH}"
        run(*args)
      rescue
        exec! "git reset --hard #{work_head}"
      ensure
        exec! "git checkout #{current}"
      end
    end

    protected

      def get_current_branch
        status, out, err = exec! "git branch | grep -e '\*'"
        out[2..-1]
      end

      def create_work_branch
        status, out, err = exec "git branch | grep -e '#{TRACK_BRANCH}'"
        track = out.strip!
        if status != 0
          status, out, err = exec! "git branch #{TRACK_BRANCH}"
        end
      end

      def get_work_head
        begin
          status, out, err = exec! "git log #{TRACK_BRANCH} --pretty=oneline | head -1"
        rescue Braid::Commands::ShellExecutionError => e
          if e.message.match("unknown revision")
            create_work_branch
            retry
          end
        end
        out.split(" ").first
      end

      def exec(cmd)
        out = ""
        err = ""
        cmd.strip!
        status = Open4::popen4(cmd) do |pid, stdin, stdout, stderr|
          out = stdout.read.strip
          err = stderr.read.strip
        end
        [status.exitstatus, out, err]
      end

      def exec!(cmd)
        status, out, err = exec(cmd)
        raise Braid::Commands::ShellExecutionError, err unless status == 0
        return status, out, err
      end

      def exec_all!(cmds)
        cmds.each_line do |cmd|
          status, out, err = exec(cmd)
          return [status, out, err] unless status
        end
        true
      end

    private

      def msg(str)
        puts "braid: " + str
      end

  end
end

require 'braid/commands/add'
require 'braid/commands/remove'
require 'braid/commands/update'
