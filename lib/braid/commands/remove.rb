# typed: strict
module Braid
  module Commands
    class Remove < Command
      class Options < T::Struct
        prop :keep, T::Boolean
      end

      sig {params(path: String, options: Options).void}
      def initialize(path, options)
        @path = path
        @options = options
      end

      private

      sig {void}
      def run_internal
        mirror = config.get!(@path)

        with_reset_on_error do
          msg "Removing mirror from '#{mirror.path}'."

          git.rm_r(mirror.path)

          config.remove(mirror)
          add_config_file

          if @options.keep
            msg "Not removing remote '#{mirror.remote}'" if verbose?
          elsif git.remote_url(mirror.remote)
            msg "Removed remote '#{mirror.path}'" if verbose?
            git.remote_rm mirror.remote
          else
            msg "Remote '#{mirror.remote}' not found, nothing to cleanup" if verbose?
          end

          git.commit("Remove mirror '#{mirror.path}'")
          msg 'Removed mirror.' if verbose?
        end
      end
    end
  end
end
