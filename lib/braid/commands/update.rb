module Braid
  module Commands
    class Update < Command
      def run(path, options = {})
        path ? update_one(path, options) : update_all(options)
      end

      protected

      def update_all(options = {})
        options.reject! { |k, v| %w(revision head).include?(k) }
        msg 'Updating all mirrors.'
        config.mirrors.each do |path|
          bail_on_local_changes!
          update_one(path, options)
        end
      end

      def update_one(path, options = {})
        mirror           = config.get!(path)

        revision_message = options['revision'] ? " to #{display_revision(mirror, options['revision'])}" : ''
        msg "Updating mirror '#{mirror.path}'#{revision_message}."

        was_locked = mirror.locked?

        # check options for lock modification
        if mirror.locked?
          if options['head']
            msg "Unlocking mirror '#{mirror.path}'." if verbose?
            mirror.lock = nil
          elsif !options['revision']
            msg "Mirror '#{mirror.path}' is locked to #{display_revision(mirror, mirror.lock)}. Use --head to force."
            return
          end
        end

        setup_remote(mirror)
        msg "Fetching new commits for '#{mirror.path}'." if verbose?
        mirror.fetch

        new_revision = options['revision']
        begin
          new_revision = validate_new_revision(mirror, new_revision)
        rescue InvalidRevision
          # Ignored as it means the revision matches expected
        end
        target_revision = determine_target_revision(new_revision)

        if (options['revision'] && was_locked && target_revision == mirror.base_revision) ||
          (options['revision'].nil? && !was_locked && mirror.merged?(target_revision))
          msg "Mirror '#{mirror.path}' is already up to date."
          clear_remote(mirror, options)
          return
        end

        if mirror.squashed?
          diff          = mirror.diff
          base_revision = mirror.base_revision
        end

        mirror.revision = new_revision
        mirror.lock = new_revision if options['revision']

        msg "Merging in mirror '#{mirror.path}'." if verbose?
        in_error = false
        begin
          if mirror.squashed?
            local_hash                    = git.rev_parse('HEAD')
            base_hash                     = generate_tree_hash(mirror, base_revision)
            remote_hash                   = generate_tree_hash(mirror, target_revision)
            ENV["GITHEAD_#{local_hash}"]  = 'HEAD'
            ENV["GITHEAD_#{remote_hash}"] = target_revision
            git.merge_trees(base_hash, local_hash, remote_hash)
          else
            git.merge_subtree(target_revision)
          end
        rescue Operations::MergeError => error
          in_error = true
          print error.conflicts_text
          msg 'Caught merge error. Breaking.'
        end

        config.update(mirror)
        add_config_file

        commit_message = "Update mirror '#{mirror.path}' to #{display_revision(mirror)}"
        if in_error
          merge_msg_path = git.repo_file_path('MERGE_MSG')
          File.open(merge_msg_path, 'w') { |f| f.puts(commit_message) }
          return
        end

        git.commit(commit_message)
        msg "Updated mirror to #{display_revision(mirror)}."
        clear_remote(mirror, options)
      end

      def generate_tree_hash(mirror, revision)
        git.with_temporary_index do
          git.read_tree_im('HEAD')
          git.rm_r_cached(mirror.path)
          git.read_tree_prefix_i(revision, mirror.path)
          git.write_tree
        end
      end
    end
  end
end
