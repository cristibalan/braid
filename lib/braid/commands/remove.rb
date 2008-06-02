module Braid
  module Commands
    class Remove < Command
      def run(mirror)
        raise Braid::Git::LocalChangesPresent if invoke(:local_changes?)

        with_reset_on_error do
          params = config.get(mirror)
          unless params
            msg "Mirror '#{mirror}/' does not exist."
            return
          end

          msg "Removing #{params["type"]} mirror from '#{mirror}/'."

          invoke(:git_rm_r, mirror)

          config.remove(mirror)
          add_config_file

          commit_message = "Remove mirror '#{mirror}/'."
          invoke(:git_commit, commit_message)
        end
      end
    end
  end
end
