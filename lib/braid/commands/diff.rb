module Braid
  module Commands
    class Diff < Command
      def run(path)
        mirror = config.get!(path)
        setup_remote(mirror)

        diff = mirror.diff
        puts diff unless diff.empty?
      end
    end
  end
end
