module Braid
  module Commands
    class Diff < Command
      def run(path, options = {})
        mirror = config.get!(path)
        setup_remote(mirror)

        diff = mirror.diff
        puts diff unless diff.empty?

        clear_remote(mirror, options)
      end
    end
  end
end
