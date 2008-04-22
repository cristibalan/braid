module Braid
  module Commands
    class Diff < Command
      def run(mirror)
        # easiest call, liek, evar.
        system("git diff #{TRACK_BRANCH} HEAD #{mirror}")
      end
    end
  end
end
