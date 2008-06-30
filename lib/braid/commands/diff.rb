module Braid
  module Commands
    class Diff < Command
      def run(path)
        mirror = config.get!(path)
        $stdout.write mirror.diff
      end
    end
  end
end
