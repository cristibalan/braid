module Braid
  module Commands
    class Mirror < Braid::Command
      def run(remote, mirror_name=nil, revision=nil)
        Init.new.run(remote, mirror_name, revision)

        unless mirror_name
          mirror = Braid::Config.new.get_from_remote(remote)
          mirror_name = mirror["dir"]
        end

        Fetch.new.run(mirror_name)
      end
    end
  end
end
