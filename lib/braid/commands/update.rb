module Braid
  module Commands
    class Update < Command
      def run(mirror, options = {})
        in_track_branch do
          mirror ? update_one(mirror, options) : update_all
        end
      end

      protected
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

          if check_for_lock(params, options)
            msg "Mirror '#{mirror}/' is locked to #{display_revision(params["type"], params["revision"])}. Skipping."
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
          rescue Braid::Commands::MirrorAlreadyUpToDate
            msg "Mirror '#{mirror}/' is already up to date. Skipping."
            update_revision(mirror, options["revision"])
            return
          end

          msg "Updating #{params["type"]} mirror '#{mirror}/'."

          if params["squash"]
            invoke(:git_rm_r, mirror)
            invoke(:git_read_tree, commit, mirror)
          else
            invoke(:git_merge_subtree, commit)
          end

          update_revision(mirror, options["revision"])
          add_config_file

          revision_message = " at " + (options["revision"] ? display_revision(params["type"], options["revision"]) : "HEAD")
          commit_message = "Update '#{mirror}/' from '#{params["remote"]}'#{revision_message}."
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
