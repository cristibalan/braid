module Braid
  module Commands
    class Diff < Command
      def run(path = nil, options = {})
        path ? diff_one(path, options) : diff_all(options)
      end

      protected

      def diff_all(options = {})
        config.mirrors.each do |path|
          separator
          msg "Diffing #{path}\n"
          separator
          diff = perform_diff(path, options)
          puts diff unless diff.empty?
        end
      end

      def diff_one(path, options = {})
        diff = perform_diff(path, options)
        puts diff unless diff.empty?
      end

      def separator
        puts "=======================================================\n"
      end

      def perform_diff(path, options = {})
        mirror = config.get!(path)
        setup_remote(mirror)

        diff = mirror.diff

        clear_remote(mirror, options)

        diff
      end
    end
  end
end
