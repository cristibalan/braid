module Braid
  module Commands
    class Diff < Command
      def run(path = nil, options = {})
        with_reset_on_error do
          path ? diff_one(path, options) : diff_all(options)
        end
      end

      protected

      def diff_all(options = {})
        print "\n"
        msg "Diffing all mirrors.\n=======================================================\n"
        config.mirrors.each do |path|
          msg "Diffing #{path}\n=======================================================\n"
          diff_one(path, options)
          msg "=======================================================\n"
        end
        print "\n"
      end

      def diff_one(path, options = {})
        mirror = config.get!(path)
        setup_remote(mirror)

        diff = mirror.diff
        puts diff unless diff.empty?

        clear_remote(mirror, options)
      end
    end
  end
end
