require 'yaml'

module Braid
  module Commands
    class Add < Braid::Command

      def run(remote, options = {})
        mirror, params = config.add_from_options(remote, options)

        local_branch = get_local_branch_name(mirror, params)
        config.update(mirror, {"local_branch" => local_branch})

        msg "Adding #{params["type"]} mirror from '#{params["remote"]}'#{", branch '#{params["branch"]}'" if params["type"] == "git"} into '#{mirror}' using local branch '#{local_branch}'."

        case params["type"]
        when "svn"
          head_revision = svn_remote_revision(params["remote"])
          msg "Got remote svn revision: #{head_revision}."

          setup_remote = <<-CMDS
            git svn init -R #{local_branch} --id=#{local_branch} #{params["remote"]}
            git svn fetch -r #{head_revision} #{local_branch}
          CMDS
        when "git"
          setup_remote = <<-CMDS
            git remote add -f -t #{params["branch"]} -m #{params["branch"]} #{local_branch} #{params["remote"]}
          CMDS
        else
          raise
        end
        msg "Setting up remote branch and fetching data."
        exec_all! setup_remote

        merge = <<-CMDS
          git merge -s ours --no-commit #{local_branch}
          git read-tree --prefix=#{mirror}/ -u #{local_branch}
          git add .braids
          git commit -m "Merge #{local_branch} into #{mirror}/" --no-verify
        CMDS
        msg "Merging code into '#{mirror}'."
        exec_all! merge

      end

      private
        def get_local_branch_name(mirror, params)
          res = "braid/#{params["type"]}/#{mirror}"
          res << "/#{params["branch"]}" if params["type"] == "git"
          res.gsub!("_", '-') # stupid git svn changes all _ to ., weird
          res
        end

        def svn_remote_revision(path)
          status, out, err = exec!("svn info #{path}")
          YAML.load(out)["Last Changed Rev"]
        end

    end
  end
end
