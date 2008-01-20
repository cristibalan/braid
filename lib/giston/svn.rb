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
      with_temp_file "gistonsvndiff" do |tmpfile|
        tmpfile << diff(repository, r1, r2)
      end
    end

    def cat(repository, file, revision, dir)
      sys("svn cat #{File.join(repository, file)}@#{revision} > #{File.join(dir, file)}")
    end

    def export(repository, revision, dir)
      sys("svn export -r #{revision} #{repository} #{dir}")
    end

    private
      def info(repository_path)
        YAML.load(sys("svn info #{repository_path}"))
      end

      def sys(*args)
        `#{args.join(' ')}`
      end

      def with_temp_file(filename, &block)
        tmpfile = Tempfile.new(filename)
        block.call tmpfile
        tmpfile.close

        tmpfile.path
      end
  end
end
