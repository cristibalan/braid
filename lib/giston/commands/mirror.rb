module Giston
  module Commands
    class Mirror < Giston::Command
      def run(remote, *args)
        Init.new.run(remote, *args)
        mirror = config.get(remote, *args)
        Fetch.new.run(mirror["dir"])
      end
    end
  end
end
