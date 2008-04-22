require 'yaml'

module Braid
  module Commands
    class Add < Command
      def run(remote, options = {})
        in_track_branch do
          mirror, params = config.add_from_options(remote, options)
          local_branch = get_local_branch_name(mirror, params)

          config.update(mirror, { "local_branch" => local_branch })
          params["local_branch"] = local_branch # TODO check

          msg "Adding #{params["type"]} mirror of '#{params["remote"]}'" + (params["type"] == "git" ? ", branch '#{params["branch"]}'" : "") + "."

          # these commands are explained in the subtree merge guide
          # http://www.kernel.org/pub/software/scm/git/docs/howto/using-merge-subtree.html

          setup_remote(mirror)
          msg "Fetching data from '#{local_branch}'."
          fetch_remote(params["type"], local_branch)

          validate_revision_option(params, options)
          commit = determine_target_commit(params, options)

          msg "Merging code into '#{mirror}/'."

          invoke(:git_merge_ours, commit)
          invoke(:git_read_tree, commit, mirror)

          config.update(mirror, { "revision" => options["revision"] })
          add_config_file

          commit_message = "Merge '#{params["remote"]}' into '#{mirror}/'."
          invoke(:git_commit, commit_message)
        end
      end

      protected
        def setup_remote(mirror)
          Braid::Command.run(:setup, mirror)
        end

      private
        def get_local_branch_name(mirror, params)
          res = "braid/#{params["type"]}/#{mirror}"
          res << "/#{params["branch"]}" if params["type"] == "git"
          res.gsub!("_", '-') # stupid git svn changes all _ to ., weird
          res
        end
    end
  end
end
