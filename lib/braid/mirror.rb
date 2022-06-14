# typed: strict
module Braid
  class Mirror
    extend T::Sig

    # Since Braid 1.1.0, the attributes are written to .braids.json in this
    # canonical order.  For now, the order is chosen to match what Braid 1.0.22
    # produced for newly added mirrors.
    ATTRIBUTES = T.let(%w(url branch path tag revision), T::Array[String])

    class UnknownType < BraidError
      sig {returns(String)}
      def message
        "unknown type: #{super}"
      end
    end
    class PathRequired < BraidError
      sig {returns(String)}
      def message
        'path is required'
      end
    end
    class NoTagAndBranch < BraidError
      sig {returns(String)}
      def message
        'can not specify both tag and branch configuration'
      end
    end

    include Operations::VersionControl

    sig {returns(String)}
    attr_reader :path

    # It's going to take significant refactoring to be able to give this a type.
    sig {returns(T::Hash[String, T.untyped])}
    attr_reader :attributes

    BreakingChangeCallback = T.type_alias { T.proc.params(arg0: String).void }

    sig {params(path: String, attributes: T::Hash[String, T.untyped], breaking_change_cb: BreakingChangeCallback).void}
    def initialize(path, attributes = {}, breaking_change_cb = DUMMY_BREAKING_CHANGE_CB)
      @path       = T.let(path.sub(/\/$/, ''), String)
      @attributes = T.let(attributes.dup, T::Hash[String, T.untyped])

      # Not that it's terribly important to check for such an old feature.  This
      # is mainly to demonstrate the RemoveMirrorDueToBreakingChange mechanism
      # in case we want to use it for something else in the future.
      if !@attributes['type'].nil? && @attributes['type'] != 'git'
        breaking_change_cb.call <<-DESC
- Mirror '#{path}' is of a Subversion repository, which is no
  longer supported.  The mirror will be removed from your configuration, leaving
  the data in the tree.
DESC
        raise Config::RemoveMirrorDueToBreakingChange
      end
      @attributes.delete('type')

      # Migrate revision locks from Braid < 1.0.18.  We no longer store the
      # original branch or tag (the user has to specify it again when
      # unlocking); we simply represent a locked revision by the absence of a
      # branch or tag.
      if @attributes['lock']
        @attributes.delete('lock')
        @attributes['branch'] = nil
        @attributes['tag'] = nil
      end

      # Removal of support for full-history mirrors from Braid < 1.0.17 is a
      # breaking change for users who wanted to use the imported history in some
      # way.
      if !@attributes['squashed'].nil? && @attributes['squashed'] != true
        breaking_change_cb.call <<-DESC
- Mirror '#{path}' is full-history, which is no longer supported.
  It will be changed to squashed.  Upstream history already imported will remain
  in your project's history and will have no effect on Braid.
DESC
      end
      @attributes.delete('squashed')
    end

    sig {params(url: String, options: T.untyped).returns(Mirror)}
    def self.new_from_options(url, options = {})
      url    = url.sub(/\/$/, '')

      raise NoTagAndBranch if options['tag'] && options['branch']

      tag = options['tag']
      branch = options['branch'] || (tag.nil? ? 'master' : nil)

      path = (options['path'] || extract_path_from_url(url, options['remote_path'])).sub(/\/$/, '')
      raise PathRequired unless path

      remote_path = options['remote_path']

      attributes = {'url' => url, 'branch' => branch, 'path' => remote_path, 'tag' => tag}
      self.new(path, attributes)
    end

    sig {params(comparison: Mirror).returns(T::Boolean)}
    def ==(comparison)
      path == comparison.path && attributes == comparison.attributes
    end

    sig {returns(T::Boolean)}
    def locked?
      branch.nil? && tag.nil?
    end

    sig {params(commit: String).returns(T::Boolean)}
    def merged?(commit)
      # tip from spearce in #git:
      # `test z$(git merge-base A B) = z$(git rev-parse --verify A)`
      commit = git.rev_parse(commit)
      !!base_revision && git.merge_base(commit, base_revision) == commit
    end

    # We'll probably call the return type something like
    # Braid::Operations::Git::TreeItem.
    sig {params(revision: String).returns(T.untyped)}
    def upstream_item_for_revision(revision)
      git.get_tree_item(revision, self.remote_path)
    end

    # Return the arguments that should be passed to "git diff" to diff this
    # mirror (including uncommitted changes by default), incorporating the given
    # user-specified arguments.  Having the caller run "git diff" is convenient
    # for now but violates encapsulation a little; we may have to reorganize the
    # code in order to add features.
    sig {params(user_args: T::Array[String]).returns(T::Array[String])}
    def diff_args(user_args = [])
      upstream_item = upstream_item_for_revision(base_revision)

      # We do not need to spend the time to copy the content outside the
      # mirror from HEAD because --relative will exclude it anyway.  Rename
      # detection seems to apply only to the files included in the diff, so we
      # shouldn't have another bug like
      # https://github.com/cristibalan/braid/issues/41.
      base_tree = git.make_tree_with_item(nil, path, upstream_item)

      # Note: --relative does a naive prefix comparison.  If we set (for
      # example) `--relative=a/b`, that will match an unrelated file or
      # directory name `a/bb`.  If the mirror is a directory, we can avoid this
      # by adding a trailing slash to the prefix.
      #
      # If the mirror is a file, the only way we can avoid matching a path like
      # `a/bb` is to pass a path argument to limit the diff.  This means if the
      # user passes additional path arguments, we won't get the behavior we
      # expect, which is the intersection of the user-specified paths with the
      # mirror.  However, it's probably unreasonable for a user to pass path
      # arguments when diffing a single-file mirror, so we ignore the issue.
      #
      # Note: This code doesn't handle various cases in which a directory at the
      # root of a mirror turns into a file or vice versa.  If that happens,
      # hopefully the user takes corrective action manually.
      if upstream_item.is_a?(git.BlobWithMode)
        # For a single-file mirror, we use the upstream basename for the
        # upstream side of the diff and the downstream basename for the
        # downstream side, like what `git diff` does when given two blobs as
        # arguments.  Use --relative to strip away the entire downstream path
        # before we add the basenames.
        return [
          '--relative=' + path,
          '--src-prefix=a/' + File.basename(T.must(remote_path)),
          '--dst-prefix=b/' + File.basename(path),
          base_tree,
          # user_args may contain options, which must come before paths.
          *user_args,
          path
        ]
      else
        return [
          '--relative=' + path + '/',
          base_tree,
          *user_args
        ]
      end
    end

    # Precondition: the remote for this mirror is set up.
    sig {returns(String)}
    def diff
      fetch_base_revision_if_missing
      git.diff(diff_args)
    end

    # Re-fetching the remote after deleting and re-adding it may be slow even if
    # all objects are still present in the repository
    # (https://github.com/cristibalan/braid/issues/71).  Mitigate this for
    # `braid diff` and other commands that need the diff by skipping the fetch
    # if the base revision is already present in the repository.
    sig {void}
    def fetch_base_revision_if_missing
      begin
        # Without ^{commit}, this will happily pass back an object hash even if
        # the object isn't present.  See the git-rev-parse(1) man page.
        git.rev_parse(base_revision + '^{commit}')
      rescue Operations::UnknownRevision
        fetch
      end
    end

    sig {void}
    def fetch
      git_cache.fetch(url) if cached?
      git.fetch(remote)
    end

    sig {returns(T::Boolean)}
    def cached?
      git.remote_url(remote) == cached_url
    end

    sig {returns(String)}
    def base_revision
      # Avoid a Sorbet "unreachable code" error.
      # TODO (typing): Is the revision expected to be non-nil nowadays?  Can we
      # just remove the `inferred_revision` code path now?
      nilable_revision = T.let(revision, T.nilable(String))
      if nilable_revision
        git.rev_parse(revision)
      else
        inferred_revision
      end
    end

    sig {returns(String)}
    def local_ref
      return "#{self.remote}/#{self.branch}" unless self.branch.nil?
      return "tags/#{self.tag}" unless self.tag.nil?
      # TODO (typing): Remove this `T.must` if we make `revision` non-nilable.
      T.must(self.revision)
    end

    # FIXME: The return value is bogus if this mirror has neither a branch nor a
    # tag.  It looks like this leads to a real bug affecting `braid push` when
    # `--branch` is specified.  File the bug or just fix it.
    sig {returns(String)}
    def remote_ref
      self.branch.nil? ? "+refs/tags/#{self.tag}" : "+refs/heads/#{self.branch}"
    end

    # Accessors for all the attributes listed in `ATTRIBUTES` and stored in
    # `self.attributes`.  Most of the accessors use the same names as the
    # underlying attributes.  The exception is the `path` attribute, whose
    # accessor is named `remote_path` to avoid a conflict with the `path`
    # accessor for the local path.
    #
    # TODO: Can we reduce this boilerplate and still type the accessors
    # statically?  If we move the config attributes to instance variables of the
    # Mirror object, then we can use `attr_accessor`, but we'd have to somehow
    # accommodate existing call sites that access `self.attributes` as a whole.

    sig {returns(String)}
    def url
      self.attributes['url']
    end

    sig {params(new_value: String).void}
    def url=(new_value)
      self.attributes['url'] = new_value
    end

    sig {returns(T.nilable(String))}
    def branch
      self.attributes['branch']
    end

    sig {params(new_value: T.nilable(String)).void}
    def branch=(new_value)
      self.attributes['branch'] = new_value
    end

    sig {returns(T.nilable(String))}
    def remote_path
      self.attributes['path']
    end

    sig {params(remote_path: T.nilable(String)).void}
    def remote_path=(remote_path)
      self.attributes['path'] = remote_path
    end

    sig {returns(T.nilable(String))}
    def tag
      self.attributes['tag']
    end

    sig {params(new_value: T.nilable(String)).void}
    def tag=(new_value)
      self.attributes['tag'] = new_value
    end

    # The revision may be nil in the middle of `braid add`.
    # TODO (typing): Look into restructuring `braid add` to avoid this?
    sig {returns(T.nilable(String))}
    def revision
      self.attributes['revision']
    end

    sig {params(new_value: String).void}
    def revision=(new_value)
      self.attributes['revision'] = new_value
    end

    sig {returns(String)}
    def cached_url
      git_cache.path(url)
    end

    sig {returns(String)}
    def remote
      "#{branch || tag || 'revision'}/braid/#{path}".gsub(/\/\./, '/_')
    end

    private

    DUMMY_BREAKING_CHANGE_CB = T.let(lambda { |desc|
      raise InternalError, 'Instantiated a mirror using an unsupported ' +
        'feature outside of configuration loading.'
    }, BreakingChangeCallback)

    sig {returns(T.nilable(String))}
    def inferred_revision
      local_commits = git.rev_list('HEAD', "-- #{path}").split("\n")
      remote_hashes = git.rev_list("--pretty=format:\"%T\"", remote).split('commit ').map do |chunk|
        chunk.split("\n", 2).map { |value| value.strip }
      end
      hash          = T.let(nil, T.nilable(String))
      local_commits.each do |local_commit|
        local_tree = git.tree_hash(path, local_commit)
        match = remote_hashes.find { |_, remote_tree| local_tree == remote_tree }
        if match
          hash = match[0]
          break
        end
      end
      hash
    end

    # TODO (typing): Return should not be nilable
    sig {params(url: String, remote_path: T.nilable(String)).returns(T.nilable(String))}
    def self.extract_path_from_url(url, remote_path)
      if remote_path
        return File.basename(remote_path)
      end

      # Avoid a Sorbet "unreachable code" error.
      # TODO (typing): Fix this properly.  Probably just remove this line?
      return nil unless T.let(url, T.nilable(String))
      name = File.basename(url)

      if File.extname(name) == '.git'
        # strip .git
        name[0..-5]
      else
        name
      end
    end
  end
end
