module Braid
  module Commands
    class Setup < Command
      def run(mirror)
        mirror ? setup_one(mirror) : setup_all
      end

      protected
        def setup_all
          msg "Setting up all mirrors."
          config.mirrors.each do |mirror|
            setup_one(mirror)
          end
        end

        def setup_one(mirror)
          params = config.get(mirror)
          unless params
            msg "Mirror '#{mirror}/' does not exist. Skipping."
            return
          end

          if find_remote(params["local_branch"])
            msg "Mirror '#{mirror}/' already has a remote. Skipping."
            return
          end

          msg "Setting up remote for '#{mirror}/'."
          case params["type"]
          when "git"
            invoke(:git_remote_add, params["local_branch"], params["remote"], params["branch"])
          when "svn"
            invoke(:git_svn_init, params["local_branch"], params["remote"])
          end
        end
    end
  end
end
