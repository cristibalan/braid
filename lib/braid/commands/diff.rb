module Braid
  module Commands
    class Diff < Command
      def run(path)
        mirror = config.get!(path)
        puts mirror.diff
      end
    end
  end
end
