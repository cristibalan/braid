module Braid
  module Commands
    class Update < Command
      def run(mirror, options = {})
        mirror ? update_one(mirror, options) : update_all
      end

      private
        def update_all
          msg "Updating all mirrors."
          config.mirrors.each do |mirror|
            update_one(mirror)
          end
        end

        def update_one(mirror, options = {})
          params = config.get(mirror)
          unless params
            msg "Mirror '#{mirror}/' does not exist. Skipping."
            return
          end

          local_branch = params["local_branch"]

          msg "Updating #{params["type"]} mirror '#{mirror}/'."

          if check_for_lock(params, options)
            msg "Mirror '#{mirror}/' is locked to #{params["revision"]}. Skipping."
            return
          end

          # unlock
          if params["revision"] && options["head"]
            msg "Unlocking mirror '#{mirror}/'."
            options["revision"] = nil 
          end

          begin
            validate_revision_option(params, options)
            commit = determine_target_commit(params, options)

            fetch_remote(params["type"], local_branch)

            check_merge_status(commit)
          rescue Braid::Commands::MirrorAlreadyUpToDate => error
            msg "Mirror '#{mirror}/' is already up to date. Skipping."
            update_revision(mirror, options["revision"])
            return
          end

          # TODO is --no-ff needed?
          status, out, err = exec!("git merge -s subtree --no-commit --no-ff #{commit}")

          # hm, this should be caught by check_merge_status
          return if out.match("Already up-to-date.")

          update_revision(mirror, options["revision"])
          add_config_file

          commit_message = "Update '#{mirror}/' from '#{params["remote"]}'."
          invoke(:git_commit, commit_message)
        end

      private
        def check_for_lock(params, options)
          params["revision"] && !options["revision"] && !options["head"]
        end

        def update_revision(mirror, revision)
          config.update(mirror, { "revision" => revision })
        end
    end
  end
end
