module Braid
  module Commands
    class List < Command
      def run(path = nil, options = {})
        msg "WARNING: list command is deprecated. Please use \"braid status\" instead.\n"
        Command.run(:status, path, options)
      end
    end
  end
end
