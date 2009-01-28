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
          options.reject! { |k,v| %w(revision head).include?(k) }
          print "\n"
          msg "Listing all mirrors.\n=======================================================\n"
          config.mirrors.each_with_index do |path, i|
             mirror = config.get!(path)
             print " #{i + 1}) #{path.to_s}"
             print " [LOCKED]" if mirror.locked?
             setup_remote(mirror)
             msg "Fetching new commits for '#{mirror.path}'." if verbose?
             mirror.fetch
             new_revision = validate_new_revision(mirror, options["revision"])
             target_revision = determine_target_revision(mirror, new_revision)
             print " !!! UPDATE AVAILABLE !!!" if new_revision.to_s != mirror.base_revision.to_s
             print "\n"
          end
          print "\n"
        end

    end
  end
end
