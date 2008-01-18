require 'tempfile'

module Giston
  class Svn
    def remote_revision(repository)
      info(repository)["Revision"]
    end

    def diff(repository, r1, r2)
      sys("svn diff -r #{r1}:#{r2} #{repository}")
    end

    def diff_file(repository, r1, r2)
      f = Tempfile.new("gistonsvndiff")
      f << diff(repository, r1, r2)
      f.close
      f.path
    end

    def cat(repository, file, revision, dir)
      sys("svn cat #{File.join(repository, file)}@#{revision} > #{File.join(dir, file)}")
    end

    def export(repository, revision, dir)
      sys("svn export -r #{revision} #{repository} #{dir}")
    end

    private
      def info(repository)
        YAML.load(sys("svn info #{repository}"))
      end

      def sys(*args)
        `#{args.join(' ')}`
      end

#      def sys(*args)
#        res = system("#{args.join(' ')}")
#        raise RepositoryNotFound unless res
#      end
  end
end
