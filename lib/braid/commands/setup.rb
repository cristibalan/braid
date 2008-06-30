module Braid
  module Commands
    class Setup < Command
      def run(path = nil)
        path ? setup_one(path) : setup_all
      end

      protected
        def setup_all
          msg "Setting up all mirrors."
          config.mirrors.each do |path|
            setup_one(path)
          end
        end

        def setup_one(path)
          mirror = config.get(path)
          unless mirror
            msg "Mirror '#{mirror.path}/' does not exist. Skipping."
            return
          end

          if git.remote_exists?(mirror.remote)
            msg "Mirror '#{mirror.path}/' already has a remote. Skipping."
            return
          end

          msg "Setting up remote for '#{mirror.path}/'."
          unless mirror.type == "svn"
            git.remote_add(mirror.remote, mirror.url, mirror.branch)
          else
            git_svn.init(mirror.remote, mirror.url)
          end
        end
    end
  end
end
