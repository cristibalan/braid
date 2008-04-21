module Braid
  module Commands
    class Remove < Command
      def run(mirror)
        params = config.get(mirror)
        unless params
          msg "Mirror '#{mirror}/' does not exist."
          return
        end

        in_track_branch do
          msg "Removing #{params["type"]} mirror from '#{mirror}/'."

          exec!("git rm -r #{mirror}")

          config.remove(mirror)
          add_config_file

          commit_message = "Remove '#{params["local_branch"]}' from '#{mirror}/'."
          invoke(:git_commit, commit_message)
        end
      end
    end
  end
end
