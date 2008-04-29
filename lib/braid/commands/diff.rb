module Braid
  module Commands
    class Diff < Command
      def run(mirror)
        # easiest call, liek, evar.
        system("git diff #{WORK_BRANCH} HEAD #{mirror}")
      end
    end
  end
end
