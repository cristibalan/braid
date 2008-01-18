module Giston
  module Commands
    class Fetch < Giston::Command
      def run(mirror_name)
        mirror = config.get(mirror_name)
        svn.export(mirror["url"], mirror["rev"], mirror["dir"])
        config.update(mirror_name, mirror)
      end
    end
  end
end
