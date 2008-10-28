module Braid
  module Commands
    class Remove < Command
      def run(path)
        mirror = config.get!(path)

        bail_on_local_changes!

        with_reset_on_error do
          msg "Removing mirror from '#{mirror.path}/'."

          git.rm_r(mirror.path)

          # will need this in case we decide to remove the .git/config entry also
          # setup_remote(mirror)

          config.remove(mirror)
          add_config_file

          commit_message = "Remove mirror '#{mirror.path}/'"
          git.commit(commit_message)
        end
      end
    end
  end
end
