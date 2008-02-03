module Braid
  module Commands
    class Forget < Braid::Command
      def run(dir)
        config.remove(dir)
      end
    end
  end
end
