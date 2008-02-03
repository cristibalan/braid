module Braid
  class Git

    def local_changes?(dir)
      dir ||= '.'
      out = sys('git-status | grep -e "#{dir}"')
      !out.empty?
    end

    private
      def sys(*args)
        `#{args.join(' ')}`
      end

#      def sys(*args)
#        res = system("#{args.join(' ')}")
#        raise RepositoryError unless res
#      end
  end
end

