require 'yaml'

module Braid
  module Commands
    class Add < Command
      def run(remote, options = {})
        mirror, params = config.add_from_options(remote, options)

        local_branch = get_local_branch_name(mirror, params)
        config.update(mirror, { "local_branch" => local_branch })
        params["local_branch"] = local_branch # TODO check

        add_message = "Adding #{params["type"]} mirror of '#{params["remote"]}'" + (params["type"] == "git" ? ", branch '#{params["branch"]}'" : "") + "."
        msg add_message

        # these commands are explained in the subtree merge guide
        # http://www.kernel.org/pub/software/scm/git/docs/howto/using-merge-subtree.html
        
        msg "Setting up remote branch '#{local_branch}' and fetching data."
        setup_remote(mirror)
        fetch_remote(params["type"], local_branch)

        validate_revision_option(params, options)
        commit = determine_target_commit(params, options)

        msg "Merging code into '#{mirror}/'."

        exec!("git merge -s ours --no-commit #{commit}")
        exec!("git read-tree --prefix=#{mirror}/ -u #{commit}")

        config.update(mirror, { "revision" => options["revision"] })
        add_config_file

        commit_message = "Merge '#{params["remote"]}' into '#{mirror}/'."
        invoke(:git_commit, commit_message)
      end

      protected
        def setup_remote(mirror)
          # no track branch magic needed
          Braid::Commands::Setup.new.run(mirror)
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
