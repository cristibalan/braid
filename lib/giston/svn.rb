require 'tempfile'

module Giston
  class Svn
    attr_accessor :repo

    def initialize(repo = nil)
      @repo = repo
    end

    def remote_revision
      info
      info["Last Changed Rev"]
    end

    def diff(r1, r2)
      sys("svn diff -r #{r1}:#{r2} #{repo}")
    end

    def diff_file(r1, r2)
      f = Tempfile.new("gistonsvndiff")
      f << diff(r1, r2)
      f.close
      f.path
    end

    def cat(file, revision, dir)
      sys("svn cat -r #{revision} #{File.join(repo, file)} > #{File.join(dir, file)}")
    end

    def export(dir, revision)
      sys("svn export -r #{revision} #{repo} #{dir}")
    end

    private
      def info
        @info ||= YAML.load(sys("svn info #{repo}"))
      end

      def sys(*args)
        `#{args.join(" ")}`
      end
  end
end
