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

          revision_message = options["revision"] ? " to #{display_revision(mirror, options["revision"])}" : ""
          msg "Updating mirror '#{mirror.path}'#{revision_message}."

          # check options for lock modification
          if mirror.locked?
            if options["head"]
              msg "Unlocking mirror '#{mirror.path}'." if verbose?
              mirror.lock = nil
            elsif !options["revision"]
              msg "Mirror '#{mirror.path}' is locked to #{display_revision(mirror, mirror.lock)}. Use --head to force."
              return
            end
          end

          setup_remote(mirror)
          msg "Fetching new commits for '#{mirror.path}'." if verbose?
          mirror.fetch

          new_revision = validate_new_revision(mirror, options["revision"])
          target_revision = determine_target_revision(mirror, new_revision)

          if mirror.merged?(target_revision)
            msg "Mirror '#{mirror.path}' is already up to date."
            return
          end

          if mirror.squashed?
            diff = mirror.diff
            base_revision = mirror.base_revision
          end

          mirror.revision = new_revision
          mirror.lock = new_revision if options["revision"]

          msg "Merging in mirror '#{mirror.path}'." if verbose?
          begin
            if mirror.squashed?
              local_hash = git.rev_parse("HEAD")
              if diff
                base_hash = generate_tree_hash(mirror, base_revision)
              else
                base_hash = local_hash
              end
              remote_hash = generate_tree_hash(mirror, target_revision)
              ENV["GITHEAD_#{local_hash}"] = "HEAD"
              ENV["GITHEAD_#{remote_hash}"] = target_revision
              git.merge_recursive(base_hash, local_hash, remote_hash)
            else
              git.merge_subtree(target_revision)
            end
          rescue Operations::MergeError => error
            msg "Caught merge error. Breaking."
          end

          config.update(mirror)
          add_config_file

          commit_message = "Updated mirror '#{mirror.path}' to #{display_revision(mirror)}"

          if error
            File.open(".git/MERGE_MSG", 'w') { |f| f.puts(commit_message) }
            return
          end

          git.commit(commit_message)
          msg commit_message
        end

        def generate_tree_hash(mirror, revision)
          git.rm_r(mirror.path)
          git.read_tree_prefix(revision, mirror.path)
          success = git.commit("Temporary commit for mirror '#{mirror.path}'")
          hash = git.rev_parse("HEAD")
          git.reset_hard("HEAD^") if success
          hash
        end
    end
  end
end
