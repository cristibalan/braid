module Braid
  module Commands
    class Diff < Command
      def run(path)
        mirror = config.get!(path)
        diff = mirror.diff
        puts diff unless diff.empty?
      end
    end
  end
end
