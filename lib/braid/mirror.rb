module Braid
  class Mirror
    TYPES      = %w(git svn)
    ATTRIBUTES = %w(url remote type branch squashed revision lock)

    class UnknownType < BraidError
      def message
        "unknown type: #{super}"
      end
    end
    class CannotGuessType < BraidError
      def message
        "cannot guess type: #{super}"
      end
    end
    class PathRequired < BraidError
      def message
        "path is required"
      end
    end

    include Operations::VersionControl

    attr_reader :path, :attributes

    def initialize(path, attributes = {})
      @path       = path.sub(/\/$/, '')
      @attributes = attributes
    end

    def self.new_from_options(url, options = {})
      url    = url.sub(/\/$/, '')

      branch = options["branch"] || "master"

      if type = options["type"] || extract_type_from_url(url)
        raise UnknownType, type unless TYPES.include?(type)
      else
        raise CannotGuessType, url
      end

      unless path = options["path"] || extract_path_from_url(url)
        raise PathRequired
      end

      if options["rails_plugin"]
        path = "vendor/plugins/#{path}"
      end

      remote   = "#{branch}/braid/#{path}".gsub("_", '-') # stupid git svn changes all _ to ., weird
      squashed = !options["full"]
      branch = nil if type == "svn"

      attributes = {"url" => url, "remote" => remote, "type" => type, "branch" => branch, "squashed" => squashed}
      self.new(path, attributes)
    end

    def ==(comparison)
      path == comparison.path && attributes == comparison.attributes
    end

    def type
      # override Object#type
      attributes["type"]
    end

    def locked?
      !!lock
    end

    def squashed?
      !!squashed
    end

    def merged?(commit)
      # tip from spearce in #git:
      # `test z$(git merge-base A B) = z$(git rev-parse --verify A)`
      commit = git.rev_parse(commit)
      if squashed?
        !!base_revision && git.merge_base(commit, base_revision) == commit
      else
        git.merge_base(commit, "HEAD") == commit
      end
    end

    def diff
      remote_hash = git.rev_parse("#{base_revision}:")
      local_hash  = git.tree_hash(path)
      remote_hash != local_hash ? git.diff_tree(remote_hash, local_hash) : ""
    end

    def fetch
      unless type == "svn"
        git_cache.fetch(url) if cached?
        git.fetch(remote)
      else
        git_svn.fetch(remote)
      end
    end

    def cached?
      git.remote_url(remote) == cached_url
    end

    def base_revision
      if revision
        unless type == "svn"
          git.rev_parse(revision)
        else
          git_svn.commit_hash(remote, revision)
        end
      else
        inferred_revision
      end
    end

    def cached_url
      git_cache.path(url)
    end

    def remote
      if (attributes["remote"] && attributes["remote"] =~ /^braid\//)
        attributes["remote"] = "#{branch}/#{attributes["remote"]}"
      else
        attributes["remote"]
      end
    end

    private

    def method_missing(name, *args)
      if ATTRIBUTES.find { |attribute| name.to_s =~ /^(#{attribute})(=)?$/ }
        unless $2
          attributes[$1]
        else
          attributes[$1] = args[0]
        end
      else
        raise NameError, "unknown attribute `#{name}'"
      end
    end

    def inferred_revision
      local_commits = git.rev_list("HEAD", "-- #{path}").split("\n")
      remote_hashes = git.rev_list("--pretty=format:\"%T\"", remote).split("commit ").map do |chunk|
        chunk.split("\n", 2).map { |value| value.strip }
      end
      hash          = nil
      local_commits.each do |local_commit|
        local_tree = git.tree_hash(path, local_commit)
        if match = remote_hashes.find { |_, remote_tree| local_tree == remote_tree }
          hash = match[0]
          break
        end
      end
      hash
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
