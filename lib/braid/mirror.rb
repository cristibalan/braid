module Braid
  class Mirror
    TYPES = %w(git svn)
    ATTRIBUTES = %w(url remote type branch squashed revision lock)

    class UnknownType < BraidError
    end
    class CannotGuessType < BraidError
    end
    class PathIsRequired < BraidError
    end

    include Operations::VersionControl

    attr_reader :path, :attributes

    def initialize(path, attributes)
      @path = path.sub(/\/$/, '')
      @attributes = attributes
    end

    def self.new_from_options(url, options = {})
      url.sub!(/\/$/, '')

      branch = options["branch"] || "master"

      if type = options["type"] || extract_type_from_url(url)
        raise UnknownType unless TYPES.include?(type)
      else
        raise CannotGuessType, url
      end

      unless path = options["path"] || extract_path_from_url(url)
        raise PathIsRequired
      end

      if options["rails_plugin"]
        path = "vendor/plugins/#{path}"
      end

      remote = "braid/#{type}/#{path}".gsub("_", '-') # stupid git svn changes all _ to ., weird
      squashed = !options["full"]

      unless type == "svn"
        remote << "/#{branch}"
      else
        branch = nil
      end

      attributes = { "url" => url, "remote" => remote, "type" => type, "branch" => branch, "squashed" => squashed, "revision" => nil, "lock" => nil }
      self.new(path, attributes)
    end

    def locked?
      # the question mark just looks nicer
      !!lock
    end

    def squashed?
      !!squashed
    end

    def ==(comparison)
      path == comparison.path && attributes == comparison.attributes
    end

    def type
      # override Object#type
      attributes["type"]
    end

    def merged?(commit)
      # tip from spearce in #git:
      # `test z$(git merge-base A B) = z$(git rev-parse --verify A)`
      commit = git.rev_parse(commit)
      unless squashed?
        git.merge_base(commit, "HEAD") == commit
      else
        git.merge_base(commit, base_revision) == commit
      end
    end

    def local_changes?
      !diff.empty?
    end

    def diff
      remote_hash = git.rev_parse(base_revision)
      local_hash = git.tree_hash(path)
      git.diff_tree(remote_hash, local_hash, path)
    end

    def fetch
      unless type == "svn"
        git.fetch(remote)
      else
        git_svn.fetch(remote)
      end
    end

    private
      def method_missing(name, *args)
        name = name.to_s
        if ATTRIBUTES.find { |attribute| name =~ /^(#{attribute})(=)?$/ }
          unless $2
            attributes[$1]
          else
            attributes[$1] = args[0]
          end
        else
          super
        end
      end

      def base_revision
        unless type == "svn"
          revision
        else
          git_svn.commit_hash(remote, revision)
        end
      end

      def self.extract_type_from_url(url)
        return nil unless url
        url.sub!(/\/$/, '')

        # check for git:// and svn:// URLs
        url_scheme = url.split(":").first
        return url_scheme if TYPES.include?(url_scheme)

        return "svn" if url[-6..-1] == "/trunk"
        return "git" if url[-4..-1] == ".git"
      end

      def self.extract_path_from_url(url)
        return nil unless url
        name = File.basename(url)

        if File.extname(name) == ".git"
          # strip .git
          name[0..-5]
        elsif name == "trunk"
          # use parent
          File.basename(File.dirname(url))
        else
          name
        end
      end
  end
end
