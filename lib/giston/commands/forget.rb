module Giston
  module Commands
    class Forget < Giston::Command
      def run(dir)
        config.remove(dir)
      end
    end
  end
end
