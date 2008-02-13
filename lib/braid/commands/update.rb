module Braid
  module Commands
    class Update < Braid::Command
      def run(mirror)
        mirror ? update_one(mirror) : update_all
      end

      private
        def update_all
          config.mirrors.each do |mirror|
            update_one(mirror)
          end
        end

        def update_one(mirror)
          params = config.get(mirror)

          case params["type"]
          when "svn"
            update_remote = <<-CMDS
              git svn fetch #{params["local_branch"]}
              git merge -s subtree #{params["local_branch"]}
            CMDS
          when "git"
            update_remote = <<-CMDS
              git fetch #{params["local_branch"]}
              git merge -s subtree #{params["local_branch"]} 
            CMDS
          else
            raise
          end
          exec_all! update_remote
        end

    end
  end
end
