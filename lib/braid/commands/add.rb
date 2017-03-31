module Braid
  module Commands
    class Add < Command
      def run(url, options = {})
        with_reset_on_error do
          mirror           = config.add_from_options(url, options)
          add_config_file

          mirror.branch = nil if options['revision']
          raise BraidError, 'Can not add mirror specifying both a revision and a tag' if options['revision'] && mirror.tag

          branch_message   = (mirror.branch.nil? || mirror.branch == 'master') ? '' : " branch '#{mirror.branch}'"
          tag_message      = mirror.tag.nil? ? '' : " tag '#{mirror.tag}'"
          revision_message = options['revision'] ? " at #{display_revision(mirror, options['revision'])}" : ''
          msg "Adding mirror of '#{mirror.url}'#{branch_message}#{tag_message}#{revision_message}."

          # these commands are explained in the subtree merge guide
          # http://www.kernel.org/pub/software/scm/git/docs/howto/using-merge-subtree.html

          config.update(mirror)
          setup_remote(mirror)
          mirror.fetch

          new_revision    = validate_new_revision(mirror, options['revision'])
          target_revision = determine_target_revision(mirror, new_revision)

          git.read_tree_prefix_u(target_revision, mirror.path)

          mirror.revision = new_revision
          config.update(mirror)
          add_config_file

          git.commit("Add mirror '#{mirror.path}' at #{display_revision(mirror)}")
          msg "Added mirror at #{display_revision(mirror)}."

          clear_remote(mirror, options)
        end
      end
    end
  end
end
