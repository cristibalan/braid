module Giston
  module Commands
    class Init < Giston::Command

      def run(remote, mirror=extract_last_part(remote), revision = nil)
        msg %(Adding mirror for #{remote} at revision #{revision} in #{mirror}.)
        revision ||= svn.remote_revision(remote)
        config.add("dir" => mirror, "url" => remote, "rev" => revision)
      end

      private
        def extract_last_part(path)
          last = File.basename(path)
          last = File.basename(File.dirname(path)) if last == "trunk"
          last
        end

    end
  end
end
