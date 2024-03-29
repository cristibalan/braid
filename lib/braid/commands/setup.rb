# typed: true
module Braid
  module Commands
    class Setup < Command
      def run(path = nil)
        path ? setup_one(path) : setup_all
      end

      private

      def setup_all
        msg 'Setting up all mirrors.'
        config.mirrors.each do |path|
          setup_one(path)
        end
      end

      def setup_one(path)
        mirror = config.get!(path)

        if git.remote_url(mirror.remote)
          if force?
            msg "Setup: Mirror '#{mirror.path}' already has a remote. Replacing it (force)" if verbose?
            git.remote_rm(mirror.remote)
          else
            msg "Setup: Mirror '#{mirror.path}' already has a remote. Reusing it." if verbose?
            return
          end
        end

        msg "Setup: Creating remote for '#{mirror.path}'." if verbose?
        url = use_local_cache? ? git_cache.path(mirror.url) : mirror.url
        git.remote_add(mirror.remote, url)
      end

      def config_mode
        Config::MODE_READ_ONLY
      end
    end
  end
end
