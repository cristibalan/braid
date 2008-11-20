module Braid
  module Commands
    class Remove < Command
      def run(path, options = {})
        mirror = config.get!(path)

        bail_on_local_changes!

        with_reset_on_error do
          msg "Removing mirror from '#{mirror.path}'."

          git.rm_r(mirror.path)

          # will need this in case we decide to remove the .git/config entry also
          # setup_remote(mirror)

          config.remove(mirror)
          add_config_file

          commit_message = "Removed mirror '#{mirror.path}'"
          git.commit(commit_message)
          msg commit_message

          if options[:keep]
            msg "Not removing remote '#{mirror.remote}'"
          elsif git.remote_url(mirror.remote)
            msg "Removed remote '#{mirror.path}'"
            git.remote_rm mirror.remote
          else
            msg "Remote '#{mirror.remote}' not found, nothing to cleanup"
          end

        end
      end
    end
  end
end
