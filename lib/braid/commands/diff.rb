module Braid
  module Commands
    class Diff < Command
      def run(mirror)
        options = config.get!(mirror)
        remote_tree = invoke(:git_rev_parse, options["local_branch"])
        local_tree = invoke(:get_tree_hash, mirror)
        puts invoke(:read_diff_tree, remote_tree, local_tree, mirror)
      end
    end
  end
end
