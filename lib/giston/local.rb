module Giston
  class Local

    def patch(diff, dir)
      sys("patch -d #{dir} -p0 < #{diff}")
    end

    def extract_binaries_from_diff(diff)
      files = sys(%(grep -e "Cannot display: file marked as a binary type." -B 2 #{diff} | grep -e "Index: " | sed -e "s/Index: //"))
    end

    private
      def sys(*args)
        `#{args.join(' ')}`
      end

#      def sys(*args)
#        res = system("#{args.join(' ')}")
#        #raise  unless res
#      end
  end
end


