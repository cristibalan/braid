# typed: strict
module Braid
  module Commands
    class Diff < Command
      class Options < T::Struct
        prop :git_diff_args, T::Array[String]
        prop :keep, T::Boolean
      end

      sig {params(path: T.nilable(String), options: Options).void}
      def initialize(path, options)
        @path = path
        @options = options
      end

      private

      sig {void}
      def run_internal
        @path ? diff_one(@path) : diff_all
      end

      sig {void}
      def diff_all
        # We don't want "git diff" to invoke the pager once for each mirror.
        # TODO: Invoke the default pager once for the entire output.
        Operations::with_modified_environment({ 'GIT_PAGER' => ''}) do
          config.mirrors.each do |path|
            separator
            msg "Diffing #{path}\n"
            separator
            show_diff(path)
          end
        end
      end

      sig {params(path: String).void}
      def diff_one(path)
        show_diff(path)
      end

      sig {void}
      def separator
        puts "=======================================================\n"
      end

      sig {params(path: String).void}
      def show_diff(path)
        mirror = config.get!(path)
        setup_remote(mirror)
        mirror.fetch_base_revision_if_missing

        # XXX: Warn if the user specifies file paths that are outside the
        # mirror?  Currently, they just won't match anything.
        git.diff_to_stdout(mirror.diff_args(@options.git_diff_args))

        clear_remote(mirror) unless @options.keep
      end

      sig {returns(Config::ConfigMode)}
      def config_mode
        Config::MODE_READ_ONLY
      end
    end
  end
end
