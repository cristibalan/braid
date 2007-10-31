module Giston
  class Git

    def local_changes?(dir)
      dir ||= '.'
      out = sys('git-status | grep -e "#{dir}"')
      return false unless local_directory_exists?(dir)
      !out.empty?
    end

    def local_directory_exists?(dir)
      File.exists?(dir)
    end

    private
      def sys(*args)
        `#{args.join(" ")}`
      end
  end
end

