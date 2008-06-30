module Braid
  module Commands
    class Update < Command
      def run(path, options = {})
        bail_on_local_changes!

        with_reset_on_error do
          path ? update_one(path, options) : update_all
        end
      end

      protected
        def update_all
          msg "Updating all mirrors."
          config.mirrors.each do |path|
            update_one(path)
          end
        end

        def update_one(path, options = {})
          mirror = config.get(path)
          unless mirror
            msg "Mirror '#{path}' does not exist. Skipping."
            return
          end

          # unlock
          if mirror.locked?
            if options["head"]
              msg "Unlocking mirror '#{mirror.path}/'."
              mirror.lock = nil
            else
              msg "Mirror '#{mirror.path}/' is locked to #{display_revision(mirror, mirror.lock)}. Skipping."
              return
            end
          end

          mirror.fetch

          new_revision = validate_new_revision(mirror, options["revision"])
          target_hash = determine_target_commit(mirror, new_revision)

          if mirror.merged?(target_hash)
            msg "Mirror '#{mirror.path}/' is already up to date. Skipping."
            return
          end

          msg "Updating mirror '#{mirror.path}/'."
          if mirror.squashed?
            if mirror.local_changes?
              msg "Mirror '#{mirror.path}/' has local changes. Aborting."
              return
            end
            git.rm_r(mirror.path)
            git.read_tree(target_hash, mirror.path)
          else
            git.merge_subtree(target_hash)
          end

          mirror.revision = new_revision

          config.update(mirror)
          add_config_file

          revision_message = " to " + (options["revision"] ? display_revision(mirror) : "HEAD")
          commit_message = "Update mirror '#{mirror.path}/'#{revision_message}"
          git.commit(commit_message)
        end
    end
  end
end
