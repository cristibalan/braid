require 'yaml'

module Braid
  module Commands
    class Add < Braid::Command

      def run(remote, options = {})
        mirror, params = config.add_from_options(remote, options)

        local_branch = get_local_branch_name(mirror, params)
        config.update(mirror, {"local_branch" => local_branch})

        add_message = "Adding #{params["type"]} mirror of '#{params["remote"]}'"
        if params["type"] == "git"
          add_message << ", branch '#{params["branch"]}'"
        end
        if options["revision"]
          add_message << " at #{display_revision(params["type"], options["revision"])}"
        end
        add_message << "."
        msg add_message

        case params["type"]
        when "svn"
          if options["revision"]
            target_revision = options["revision"]
          else
            target_revision = svn_remote_head_revision(params["remote"])
            msg "Got remote svn revision: #{target_revision}."
          end

          setup_remote = <<-CMDS
            git svn init -R #{local_branch} --id=#{local_branch} #{params["remote"]}
            git svn fetch -r #{target_revision} #{local_branch}
          CMDS
        when "git"
          setup_remote = <<-CMDS
            git remote add -f -t #{params["branch"]} -m #{params["branch"]} #{local_branch} #{params["remote"]}
          CMDS
        else
          raise Braid::Config::UnknownMirrorType, params["type"]
        end
        msg "Setting up remote branch '#{local_branch}' and fetching data."
        exec_all! setup_remote

        # svn is already limited to the revision specified with fetch
        treeish = (params["type"] != "svn" && options["revision"]) ? options["revision"] : local_branch

        # these commands are explained in the subtree merge guide
        # http://www.kernel.org/pub/software/scm/git/docs/howto/using-merge-subtree.html
        read_tree = <<-CMDS
          git merge -s ours --no-commit #{treeish}
          git read-tree --prefix=#{mirror}/ -u #{treeish}
        CMDS
        #msg "Reading tree into '#{mirror}/'."
        exec_all! read_tree

        revision = clean_revision(params["type"], options["revision"])
        # this has to happen later to resolve partial identifiers
        #msg "Locking '#{mirror}/' to revision '#{revision}'."
        config.update(mirror, {"revision" => revision})

        commit_message = "Merge '#{params["remote"]}' into '#{mirror}/'."
        merge = <<-CMDS
          git add .braids
          git commit -m #{commit_message.inspect} --no-verify
        CMDS
        msg "Merging code into '#{mirror}/'."
        exec_all! merge
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
