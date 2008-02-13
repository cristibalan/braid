module Braid
  module Commands
    class Remove < Braid::Command
      def run(mirror)
        params = config.get(mirror)

        msg "Removign #{params["type"]} mirror from '#{mirror}'."
        config.remove(mirror)

        remove_dir = <<-CMDS
          git rm #{mirror}
          git add .braids
          git commit -m "Remove #{params["local_branch"]} from #{mirror}/"
        CMDS
        exec_all! remove_dir
      end
    end
  end
end
