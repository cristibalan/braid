module Braid
  module Commands
    class Diff < Command
      def run(path = nil, options = {})
        path ? diff_one(path, options) : diff_all(options)
      end

      protected

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

        # We do not need to spend the time to copy the content outside the
        # mirror from HEAD because --relative will exclude it anyway.  Rename
        # detection seems to apply only to the files included in the diff, so we
        # shouldn't have another bug like
        # https://github.com/cristibalan/braid/issues/41.
        base_tree = git.make_tree_with_subtree(nil, mirror.path,
          mirror.versioned_path(mirror.base_revision))
        # Git 1.7.2.2 release notes mention a bug when --relative is used
        # without a trailing slash, and our minimum git version is 1.6.0, so
        # attempt to work around the bug here.
        #
        # XXX: Warn if the user specifies file paths that are outside the
        # mirror?  Currently, they just won't match anything.
        git.diff_to_stdout("--relative=#{mirror.path}/", base_tree, options['git_diff_args'])

        clear_remote(mirror, options)
      end
    end
  end
end
