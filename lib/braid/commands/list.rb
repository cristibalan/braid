module Braid
  module Commands
    class List < Command
      def run(path = nil, options = {})
        with_reset_on_error do
          path ? list_one(path, options) : list_all(options)
        end
      end

      protected
      def list_all(options = {})
        options.reject! { |k, v| %w(revision head).include?(k) }
        print "\n"
        msg "Listing all mirrors.\n=======================================================\n"
        config.mirrors.each do |path|
          mirror = config.get!(path)
          print path.to_s
          print ' [LOCKED]' if mirror.locked?
          setup_remote(mirror)
          msg "Fetching new commits for '#{mirror.path}'." if verbose?
          mirror.fetch
          new_revision    = validate_new_revision(mirror, options['revision'])
          print ' (Remote Modified)' if new_revision.to_s != mirror.base_revision.to_s
          print ' (Locally Modified)' unless mirror.diff.empty?
          print "\n"
        end
        print "\n"
      end

    end
  end
end
