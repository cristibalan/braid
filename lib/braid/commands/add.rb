# typed: strict
module Braid
  module Commands
    class Add < Command
      # Returns the default branch name of the repository at the given URL, or
      # nil if it couldn't be determined.
      #
      # We won't be able to determine a default branch in certain cases that we
      # expect to be unusual in the context of Braid, such as if the HEAD is
      # detached or points to a ref outside of `refs/heads`.  (Presumably, the
      # same thing happens if the server is too old to report symrefs to us.)
      # In those cases, a plausible alternative behavior would be to just lock
      # the mirror to the remote HEAD revision, but that's probably not what the
      # user wants.  It's much more likely that something is wrong and Braid
      # should report an error.
      sig {params(url: String).returns(T.nilable(String))}
      def get_default_branch_name(url)
        head_targets = []
        # The `HEAD` parameter here doesn't appear to do an exact match (it
        # appears to match any ref with `HEAD` as the last path component, such
        # as `refs/remotes/origin/HEAD` in the unusual case where the repository
        # contains its own remote-tracking branches), but it reduces the data we
        # have to scan a bit.
        git.ls_remote(['--symref', url, 'HEAD']).split("\n").each do |line|
          m = /^ref: (.*)\tHEAD$/.match(line)
          head_targets.push(m[1]) if m
        end
        return nil unless head_targets.size == 1
        m = /^refs\/heads\/(.*)$/.match(head_targets[0])
        return nil unless m
        m[1]
      end

      sig {params(url: String, options: Mirror::Options).void}
      def initialize(url, options)
        @url = url
        @options = options
      end

      private

      sig {void}
      def run_internal
        with_reset_on_error do
          if @options.branch.nil? && @options.tag.nil? && @options.revision.nil?
            default_branch = get_default_branch_name(@url)
            if default_branch.nil?
              raise BraidError, <<-MSG
Failed to detect the default branch of the remote repository.  Please specify
the branch you want to use via the --branch option.
MSG
            end
            @options.branch = default_branch
          end

          mirror           = config.add_from_options(@url, @options)
          add_config_file

          mirror.branch = nil if @options.revision
          raise BraidError, 'Can not add mirror specifying both a revision and a tag' if @options.revision && mirror.tag

          branch_message   = mirror.branch.nil? ? '' : " branch '#{mirror.branch}'"
          tag_message      = mirror.tag.nil? ? '' : " tag '#{mirror.tag}'"
          revision_message = @options.revision ? " at #{display_revision(mirror, @options.revision)}" : ''
          msg "Adding mirror of '#{mirror.url}'#{branch_message}#{tag_message}#{revision_message}."

          # these commands are explained in the subtree merge guide
          # http://www.kernel.org/pub/software/scm/git/docs/howto/using-merge-subtree.html

          config.update(mirror)
          setup_remote(mirror)
          mirror.fetch

          new_revision = validate_new_revision(mirror, @options.revision)
          target_item = mirror.upstream_item_for_revision(new_revision)

          git.add_item_to_index(target_item, mirror.path, true)

          mirror.revision = new_revision
          config.update(mirror)
          add_config_file

          git.commit("Add mirror '#{mirror.path}' at #{display_revision(mirror)}")
          msg "Added mirror at #{display_revision(mirror)}."

          clear_remote(mirror)
        end
      end
    end
  end
end
