module Braid
  module Commands
    class Diff < Command
      def run(path = nil, options = {})
        path ? diff_one(path, options) : diff_all(options)
      end

      private

      def diff_all(options = {})
        # We don't want "git diff" to invoke the pager once for each mirror.
        # TODO: Invoke the default pager once for the entire output.
        Operations::with_modified_environment({"GIT_PAGER" => ''}) do
          config.mirrors.each do |path|
            separator
            msg "Diffing #{path}\n"
            separator
            show_diff(path, options)
          end
        end
      end

      def diff_one(path, options = {})
        show_diff(path, options)
      end

      def separator
        puts "=======================================================\n"
      end

      def show_diff(path, options = {})
        mirror = config.get!(path)
        setup_remote(mirror)
        mirror.fetch_base_revision_if_missing

        # XXX: Warn if the user specifies file paths that are outside the
        # mirror?  Currently, they just won't match anything.
        git.diff_to_stdout(*mirror.diff_args(*options['git_diff_args']))

        clear_remote(mirror, options)
      end

      def config_mode
        Config::MODE_READ_ONLY
      end
    end
  end
end
