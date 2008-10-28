module Braid
  module Commands
    class Add < Command
      def run(url, options = {})
        bail_on_local_changes!

        with_reset_on_error do
          mirror = config.add_from_options(url, options)

          branch_message = (mirror.type == "svn" || mirror.branch == "master") ? "" : " branch '#{mirror.branch}'"
          revision_message = options["revision"] ? " at #{display_revision(mirror, options["revision"])}" : ""
          msg "Adding #{mirror.type} mirror of '#{mirror.url}'#{branch_message}#{revision_message}."

          # these commands are explained in the subtree merge guide
          # http://www.kernel.org/pub/software/scm/git/docs/howto/using-merge-subtree.html

          setup_remote(mirror)
          mirror.fetch

          new_revision = validate_new_revision(mirror, options["revision"])
          target_revision = determine_target_revision(mirror, new_revision)

          unless mirror.squashed?
            git.merge_ours(target_revision)
          end
          git.read_tree_prefix(target_revision, mirror.path)

          mirror.revision = new_revision
          mirror.lock = new_revision if options["revision"]
          config.update(mirror)
          add_config_file

          commit_message = "Added mirror '#{mirror.path}' at #{display_revision(mirror)}"

          git.commit(commit_message)
          msg commit_message
        end
      end

    end
  end
end
