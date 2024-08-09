# typed: strict
module Braid
  module Commands
    class Setup < Command
      sig {params(path: T.nilable(String)).void}
      def initialize(path = nil)
        @path = path
      end

      private

      sig {void}
      def run_internal
        @path ? setup_one(@path) : setup_all
      end

      sig {void}
      def setup_all
        msg 'Setting up all mirrors.'
        config.mirrors.each do |path|
          setup_one(path)
        end
      end

      sig {params(path: String).void}
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

      sig {returns(Config::ConfigMode)}
      def config_mode
        Config::MODE_READ_ONLY
      end
    end
  end
end
