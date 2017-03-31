module Braid
  module Commands
    class Status < Command
      def run(path = nil, options = {})
        path ? status_one(path, options) : status_all(options)
      end

      protected

      def status_all(options = {})
        print "\n"
        msg "Listing all mirrors.\n=======================================================\n"
        config.mirrors.each do |path|
          status_one(path, options)
        end
        print "\n"
      end

      def status_one(path, options = {})
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
        new_revision = validate_new_revision(mirror, options['revision'])
        print ' (Remote Modified)' if new_revision.to_s != mirror.base_revision.to_s
        local_file_count = git.read_ls_files(mirror.path).split.size
        if 0 == local_file_count
          print ' (Removed Locally)'
        elsif !mirror.diff.empty?
          print ' (Locally Modified)'
        end
        print "\n"
        clear_remote(mirror, options)
      end
    end
  end
end
