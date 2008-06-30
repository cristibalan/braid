module Braid
  module Commands
    class Add < Command
      def run(url, options = {})
        bail_on_local_changes!

        with_reset_on_error do
          mirror = config.add_from_options(url, options)

          branch_message = (mirror.type == "svn" || mirror.branch == "master") ? "" : " branch '#{mirror.branch}'"
          msg "Adding #{mirror.type} mirror of '#{mirror.url}'#{branch_message}."

          # these commands are explained in the subtree merge guide
          # http://www.kernel.org/pub/software/scm/git/docs/howto/using-merge-subtree.html

          setup_remote(mirror)
          mirror.fetch

          new_revision = validate_new_revision(mirror, options["revision"])
          target_hash = determine_target_commit(mirror, new_revision)

          unless mirror.squashed?
            git.merge_ours(target_hash)
          end
          git.read_tree(target_hash, mirror.path)

          mirror.revision = new_revision
          config.update(mirror)

          add_config_file

          revision_message = options["revision"] ? " at #{display_revision(mirror)}" : ""
          commit_message = "Add mirror '#{mirror.path}/'#{revision_message}"
          git.commit(commit_message)
        end
      end

      private
        def setup_remote(mirror)
          Command.run(:setup, mirror.path)
        end
    end
  end
end
