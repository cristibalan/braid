# typed: strict
module Braid
  module Commands
    class Update < Command
      class Options < T::Struct
        prop :branch, T.nilable(String)
        prop :tag, T.nilable(String)
        prop :revision, T.nilable(Operations::Git::ObjectExpr)
        prop :head, T::Boolean
        prop :keep, T::Boolean
      end

      sig {params(path: T.nilable(String), options: Options).void}
      def initialize(path, options)
        @path = path
        @options = options
      end

      private

      sig {void}
      def run_internal
        @path ? update_one(@path) : update_all
      end

      sig {void}
      def update_all
        # Maintain previous behavior of ignoring these options when updating all
        # mirrors.  TODO: Should we make it an error if the options were passed?
        @options.revision = nil
        @options.head = false

        msg 'Updating all mirrors.'
        config.mirrors.each do |path|
          bail_on_local_changes!
          update_one(path)
        end
      end

      sig {params(path: String).void}
      def update_one(path)
        bail_on_local_changes!

        raise BraidError, "Do not specify --head option anymore. Please use '--branch MyBranch' to track a branch or '--tag MyTag' to track a branch" if @options.head

        mirror           = config.get!(path)

        msg "Updating mirror '#{mirror.path}'."

        was_locked = mirror.locked?
        original_revision = mirror.revision
        original_branch = mirror.branch
        original_tag = mirror.tag

        raise BraidError, 'Can not update mirror specifying both a revision and a tag' if @options.revision && @options.tag
        raise BraidError, 'Can not update mirror specifying both a branch and a tag' if @options.branch && @options.tag

        if @options.tag
          mirror.tag = @options.tag
          mirror.branch = nil
        elsif @options.branch
          mirror.tag = nil
          mirror.branch = @options.branch
        elsif @options.revision
          mirror.tag = nil
          mirror.branch = nil
        end

        config.update(mirror)

        setup_remote(mirror)
        msg "Fetching new commits for '#{mirror.path}'." if verbose?
        mirror.fetch

        new_revision = @options.revision
        begin
          new_revision = validate_new_revision(mirror, new_revision)
        rescue InvalidRevision
          # Ignored as it means the revision matches expected
          # This can only happen if new_revision was non-nil.
          # TODO (typing): Untangle the logic and remote this `T.must`.
          new_revision = T.must(new_revision)
        end

        from_desc =
          original_tag ? "tag '#{original_tag}'" :
            !was_locked ? "branch '#{original_branch}'" :
              "revision '#{original_revision}'"

        switching = true
        if mirror.branch && (original_branch != mirror.branch || (was_locked && !mirror.locked?))
          msg "Switching mirror '#{mirror.path}' to branch '#{mirror.branch}' from #{from_desc}."
        elsif mirror.tag && original_tag != mirror.tag
          msg "Switching mirror '#{mirror.path}' to tag '#{mirror.tag}' from #{from_desc}."
        elsif @options.revision && original_revision != @options.revision
          msg "Switching mirror '#{mirror.path}' to revision '#{@options.revision}' from #{from_desc}."
        else
          switching = false
        end

        if !switching &&
          (
            (@options.revision && was_locked && new_revision == mirror.base_revision) ||
            (@options.revision.nil? && !was_locked && mirror.merged?(git.rev_parse(new_revision)))
          )
          msg "Mirror '#{mirror.path}' is already up to date."
          clear_remote(mirror) unless @options.keep
          return
        end

        base_revision = mirror.base_revision

        mirror.revision = new_revision

        msg "Merging in mirror '#{mirror.path}'." if verbose?
        in_error = false
        begin
          local_hash = git.rev_parse('HEAD')
          base_hash = git.make_tree_with_item('HEAD', mirror.path,
            mirror.upstream_item_for_revision(base_revision))
          remote_hash = git.make_tree_with_item('HEAD', mirror.path,
            mirror.upstream_item_for_revision(new_revision))
          Operations::with_modified_environment({
            "GITHEAD_#{local_hash}" => 'HEAD',
            "GITHEAD_#{remote_hash}" => new_revision
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
        clear_remote(mirror) unless @options.keep
      end
    end
  end
end
