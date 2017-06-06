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
        bail_on_local_changes!

        raise BraidError, "Do not specify --head option anymore. Please use '--branch MyBranch' to track a branch or '--tag MyTag' to track a branch" if options['head']

        mirror           = config.get!(path)

        msg "Updating mirror '#{mirror.path}'."

        was_locked = mirror.locked?
        original_revision = mirror.revision
        original_branch = mirror.branch
        original_tag = mirror.tag

        raise BraidError, 'Can not update mirror specifying both a revision and a tag' if options['revision'] && options['tag']
        raise BraidError, 'Can not update mirror specifying both a branch and a tag' if options['branch'] && options['tag']

        if options['tag']
          mirror.tag = options['tag']
          mirror.branch = nil
        elsif options['branch']
          mirror.tag = nil
          mirror.branch = options['branch']
        elsif options['revision']
          mirror.tag = nil
          mirror.branch = nil
        end

        config.update(mirror)

        setup_remote(mirror)
        msg "Fetching new commits for '#{mirror.path}'." if verbose?
        mirror.fetch

        new_revision = options['revision']
        begin
          new_revision = validate_new_revision(mirror, new_revision)
        rescue InvalidRevision
          # Ignored as it means the revision matches expected
        end
        target_revision = determine_target_revision(mirror, new_revision)
        current_revision = determine_target_revision(mirror, mirror.base_revision)

        from_desc =
          original_tag ? "tag '#{original_tag}'" :
            !was_locked ? "branch '#{original_branch}'" :
              "revision '#{original_revision}'"

        switching = true
        if mirror.branch && (original_branch != mirror.branch || (was_locked && !mirror.locked?))
          msg "Switching mirror '#{mirror.path}' to branch '#{mirror.branch}' from #{from_desc}."
        elsif mirror.tag && original_tag != mirror.tag
          msg "Switching mirror '#{mirror.path}' to tag '#{mirror.tag}' from #{from_desc}."
        elsif options['revision'] && original_revision != options['revision']
          msg "Switching mirror '#{mirror.path}' to revision '#{options['revision']}' from #{from_desc}."
        else
          switching = false
        end

        if !switching &&
          (
            (options['revision'] && was_locked && target_revision == current_revision) ||
            (options['revision'].nil? && !was_locked && mirror.merged?(git.rev_parse(new_revision)))
          )
          msg "Mirror '#{mirror.path}' is already up to date."
          clear_remote(mirror, options)
          return
        end

        base_revision = mirror.base_revision

        mirror.revision = new_revision

        msg "Merging in mirror '#{mirror.path}'." if verbose?
        in_error = false
        begin
          local_hash = git.rev_parse('HEAD')
          base_hash = git.make_tree_with_subtree('HEAD', mirror.path, mirror.versioned_path(base_revision))
          remote_hash = git.make_tree_with_subtree('HEAD', mirror.path, target_revision)
          Operations::with_modified_environment({
            "GITHEAD_#{local_hash}" => 'HEAD',
            "GITHEAD_#{remote_hash}" => target_revision
          }) do
            git.merge_trees(base_hash, local_hash, remote_hash)
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
    end
  end
end
