module Braid
  module Commands
    class Init < Braid::Command

      def run(remote, mirror=nil, revision=nil)
        mirror ||= extract_last_part(remote)
        revision ||= svn.remote_revision(remote)
        msg %(Adding mirror for #{remote} at revision #{revision} in #{mirror}.)
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
