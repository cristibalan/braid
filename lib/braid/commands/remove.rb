module Braid
  module Commands
    class Remove < Command
      def run(path)
        mirror = config.get!(path)

        bail_on_local_changes!

        with_reset_on_error do
          msg "Removing mirror from '#{mirror.path}/'."

          git.rm_r(mirror.path)

          config.remove(mirror)
          add_config_file

          commit_message = "Remove mirror '#{mirror.path}/'"
          git.commit(commit_message)
        end
      end
    end
  end
end
