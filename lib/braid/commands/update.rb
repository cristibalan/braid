module Braid
  module Commands
    class Update < Command
      def run(path, options = {})
        bail_on_local_changes!

        with_reset_on_error do
          path ? update_one(path, options) : update_all(options)
        end
      end

      protected
        def update_all(options = {})
          options.reject! { |k,v| %w(revision head).include?(k) }
          msg "Updating all mirrors."
          config.mirrors.each do |path|
            update_one(path, options)
          end
        end

        def update_one(path, options = {})
          mirror = config.get!(path)

          # check options for lock modification
          if mirror.locked?
            if options["head"]
              msg "Unlocking mirror '#{mirror.path}/'."
              mirror.lock = nil
            elsif !options["revision"]
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

          diff = mirror.diff if mirror.squashed? # get diff before setting revision

          mirror.revision = new_revision
          mirror.lock = new_revision if options["revision"]
          config.update(mirror)

          msg "Updating mirror '#{mirror.path}/'."
          begin
            if mirror.squashed?
              git.rm_r(mirror.path)
              git.read_tree(target_hash, mirror.path)
              unless diff.empty?
                git.apply(diff, *(options["safe"] ? ["--reject"] : []))
              end
            else
              git.merge_subtree(target_hash)
            end
          rescue Operations::ShellExecutionError => error
            msg "Caught merge error. Breaking."
          end

          add_config_file

          revision_message = " to " + (options["revision"] ? display_revision(mirror) : "HEAD")
          commit_message = "Update mirror '#{mirror.path}/'#{revision_message}"

          if error
            File.open(".git/MERGE_MSG", 'w') { |f| f.puts(commit_message) }
            return
          else
            git.commit(commit_message)
          end
        end
    end
  end
end
