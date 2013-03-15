module Braid
  module Commands
    class Add < Command
      def run(url, options = {})
        bail_on_local_changes!

        with_reset_on_error do
          mirror           = config.add_from_options(url, options)

          branch_message   = (mirror.branch == "master") ? "" : " branch '#{mirror.branch}'"
          revision_message = options["revision"] ? " at #{display_revision(mirror, options["revision"])}" : ""
          msg "Adding mirror of '#{mirror.url}'#{branch_message}#{revision_message}."

          # these commands are explained in the subtree merge guide
          # http://www.kernel.org/pub/software/scm/git/docs/howto/using-merge-subtree.html

          setup_remote(mirror)
          mirror.fetch

          new_revision    = validate_new_revision(mirror, options["revision"])
          target_revision = determine_target_revision(new_revision)

          unless mirror.squashed?
            git.merge_ours(target_revision)
          end
          git.read_tree_prefix(target_revision, mirror.path)

          mirror.revision = new_revision
          mirror.lock = new_revision if options["revision"]
          config.update(mirror)
          add_config_file

          git.commit("Add mirror '#{mirror.path}' at #{display_revision(mirror)}")
          msg "Added mirror at #{display_revision(mirror)}."
        end
      end

    end
  end
end
