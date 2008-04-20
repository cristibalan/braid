require 'rubygems'
require 'open4'

module Braid
  class Command

    TRACK_BRANCH = "braid/track"

    attr_accessor :config

    def initialize(options = {})
      @config = options["config"] || Braid::Config.new
      #@cli = options["cli"] || Braid::Cli.new
    end

    def self.run(command, *args)
      klass = Braid::Commands.const_get(command.to_s.capitalize)
      klass.new.run_in_track_branch(*args)
    rescue => e
      # FIXME
      msg "Error occured at: #{e.backtrace.first}."
    end

    def run_in_track_branch(*args)
      current = get_current_branch

      create_work_branch
      work_head = get_work_head

      begin
        msg "Checking out work branch '#{TRACK_BRANCH}'."
        exec! "git checkout #{TRACK_BRANCH}"
        run(*args)
      rescue => e
        msg "Error occured: #{e}"
        if get_current_branch == TRACK_BRANCH
          msg "Resetting #{TRACK_BRANCH} to #{work_head}."
          exec! "git reset --hard #{work_head}"
        end
        raise e
      ensure
        msg "Checking out branch '#{current}'."
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
          msg "Creating work branch '#{TRACK_BRANCH}'"
          status, out, err = exec! "git branch #{TRACK_BRANCH}"
        end
      end

      def get_work_head
        get_revision_hash(TRACK_BRANCH)
      end

      def get_revision_hash(treeish)
        retried = false # FIXME surely there must be a better way?
        begin
          status, out, err = exec! "git log #{treeish} --pretty=oneline | head -1"
        rescue Braid::Commands::ShellExecutionError => e
          unless retried
            if e.message.match("unknown revision")
              create_work_branch
              retried = true
              retry
            end
          end

          raise Braid::Git::UnknownRevision, treeish
        end
        out.split(" ").first
      end

      def exec(cmd)
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

      def exec!(cmd)
        status, out, err = exec(cmd)
        raise Braid::Commands::ShellExecutionError, err unless status == 0
        return status, out, err
      end

      def exec_all!(cmds)
        cmds.each_line do |cmd|
          exec!(cmd)
        end
        true
      end

      # TODO following helpers need cleaning

      def svn_remote_head_revision(path)
        # not using svn info because it's retarded and doesn't show the actual last changed rev for the url
        # also, git svn has no clue on how to get the actual HEAD revision number on it's own
        status, out, err = exec!("svn log -q --limit 1 #{path}")
        out.split(/\n/).find {|x| x.match /^r\d+/}.split(" ")[0][1..-1]
      end

      def clean_revision(type, revision)
        if revision
          # ensures nice formatting and whatnot
          type == "svn" ? revision.to_i : get_revision_hash(revision)
        end
      end

      def display_revision(type, revision)
        # assumes "cleaned" identifier
        if revision
          type == "svn" ? "r#{revision}" : revision.to_s[0..6]
        end
      end

    private

      def self.msg(str)
        puts "braid: " + str
      end
      def msg(str)
        self.class.msg(str)
      end

  end
end

require 'braid/commands/add'
require 'braid/commands/remove'
require 'braid/commands/update'
