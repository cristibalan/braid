module Braid
  module Commands
    class Remove < Command
      def run(path, options = {})
        mirror = config.get!(path)

        bail_on_local_changes!

        with_reset_on_error do
          msg "Removing mirror from '#{mirror.path}'."

          git.rm_r(mirror.path)

          config.remove(mirror)
          add_config_file

          if options[:keep]
            msg "Not removing remote '#{mirror.remote}'" if verbose?
          elsif git.remote_url(mirror.remote)
            msg "Removed remote '#{mirror.path}'" if verbose?
            git.remote_rm mirror.remote
          else
            msg "Remote '#{mirror.remote}' not found, nothing to cleanup" if verbose?
          end

          commit_message = "Removed mirror '#{mirror.path}'"
          git.commit(commit_message)
          msg commit_message
        end
      end
    end
  end
end
