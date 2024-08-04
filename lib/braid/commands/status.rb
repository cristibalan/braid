# typed: strict
module Braid
  module Commands
    class Status < Command
      sig {params(path: T.nilable(String)).void}
      def initialize(path)
        @path = path
      end

      private

      sig {void}
      def run_internal
        @path ? status_one(@path) : status_all
      end

      sig {void}
      def status_all
        print "\n"
        msg "Listing all mirrors.\n=======================================================\n"
        config.mirrors.each do |path|
          status_one(path)
        end
        print "\n"
      end

      sig {params(path: String).void}
      def status_one(path)
        mirror = config.get!(path)
        setup_remote(mirror)
        mirror.fetch
        print path.to_s
        print ' (' + mirror.base_revision + ')'
        if mirror.locked?
          print ' [REVISION LOCKED]'
        elsif mirror.tag
          print " [TAG=#{mirror.tag}]"
        else # mirror.branch
          print " [BRANCH=#{mirror.branch}]"
        end
        msg "Fetching new commits for '#{mirror.path}'." if verbose?
        new_revision = validate_new_revision(mirror, nil)
        print ' (Remote Modified)' if new_revision.to_s != mirror.base_revision.to_s
        local_file_count = git.read_ls_files(mirror.path).split.size
        if 0 == local_file_count
          print ' (Removed Locally)'
        elsif !mirror.diff.empty?
          print ' (Locally Modified)'
        end
        print "\n"
        clear_remote(mirror)
      end

      sig {returns(Config::ConfigMode)}
      def config_mode
        Config::MODE_READ_ONLY
      end
    end
  end
end
