require 'fileutils'
require 'tmpdir'

module Braid
    class NoPushToTag < BraidError
      def message
        "mirror is based off a tag. Can not push to a tag: #{super}"
      end
    end

  module Commands
    class Push < Command
      def run(path, options = {})
        mirror = config.get!(path)

        branch = options['branch'] || mirror.branch

        raise NoPushToTag, path unless branch

        setup_remote(mirror)
        mirror.fetch

        base_revision = determine_repository_revision(mirror)
        unless mirror.merged?(base_revision)
          msg 'Mirror is not up to date. Stopping.'
          clear_remote(mirror, options)
          return
        end

        diff = mirror.diff
        if diff.empty?
          msg 'No local changes found. Stopping.'
          clear_remote(mirror, options)
          return
        end
        local_mirror_item = git.get_tree_item('HEAD', mirror.path)

        odb_paths = [File.expand_path(git.repo_file_path('objects'))]
        if File.exist?(mirror.cached_url)
          Dir.chdir(mirror.cached_url) do
            odb_paths.push(File.expand_path(git.repo_file_path('objects')))
          end
        end
        clone_dir = Dir.tmpdir + "/braid_push.#{$$}"
        Dir.mkdir(clone_dir)
        remote_url = git.remote_url(mirror.remote)
        if remote_url == mirror.cached_url
          remote_url = mirror.url
        elsif File.directory?(remote_url)
          remote_url = File.expand_path(remote_url)
        end
        user_name = git.config(%w(--local --get user.name))
        user_email = git.config(%w(--local --get user.email))
        commit_gpgsign = git.config(%w(--local --get commit.gpgsign))
        Dir.chdir(clone_dir) do
          msg 'Cloning mirror with local changes.'
          git.init
          git.config(['--local', 'user.name', "\"#{user_name}\""]) if user_name
          git.config(['--local', 'user.email', "\"#{user_email}\""]) if user_email
          git.config(['--local', 'commit.gpgsign', commit_gpgsign]) if commit_gpgsign
          # Adding other repositories as alternates is safe (we don't have to
          # worry about them being moved or deleted during the lifetime of this
          # temporary repository) and faster than fetching from them.  We don't
          # need git.repo_file_path because the temporary repository isn't using
          # a linked worktree.  Git for Windows seems to want LF and not CRLF in
          # the alternates file; hope that works for Cygwin Git, etc. too.
          File.open('.git/objects/info/alternates', 'wb') { |f|
            f.puts(odb_paths)
          }
          git.fetch(remote_url, mirror.remote_ref)
          new_tree = git.make_tree_with_item(base_revision,
            mirror.remote_path || '', local_mirror_item)
          if git.require_version('2.27')
            # Skip checking files out into the working tree by turning on sparse
            # checkout with an empty list of include patterns (which is an error
            # before Git 2.27).  This improves performance and avoids problems
            # with filters that are enabled globally but aren't set up properly
            # in the temporary repository (e.g., potentially, Git LFS).
            #
            # It's not ideal to rely on an edge case of an advanced Git feature,
            # but the alternatives aren't great either.  We want to run `git
            # commit` interactively for the user; we can't just call
            # git.make_tree_with_item + `git commit-tree`.  And if we populate
            # the index and not the working tree without using sparse checkout,
            # then `git commit` will show all files as deleted under "Changes
            # not staged for commit", which is distracting.
            #
            # Manipulating index entries that are excluded by sparse checkout is
            # extremely dicey: depending on the Git version, `git checkout` and
            # `git rm` may leave them unchanged and not perform the operation we
            # requested.  So it's safest to generate the new tree before we
            # enable sparse checkout.  After enabling sparse checkout (if our
            # copy of Git indeed supports it), `git read-tree -u` is one
            # operation that should be safe: the index update is unconditional,
            # and the working tree update honors sparse checkout.
            #
            # TODO: Audit Braid for operations that could be broken by use of
            # sparse checkout by the user (rather than internal to `braid
            # push`)?
            git.config(['--local', 'core.sparsecheckout', 'true'])
            File.open('.git/info/sparse-checkout', 'wb') { |f|
              # Leave the file empty.
            }
          end
          # Update HEAD the same way git.checkout(base_revision) would, but
          # don't populate the index or working tree (to save us the trouble of
          # emptying them again before the git.read_tree).
          git.update_ref('--no-deref', 'HEAD', base_revision)
          git.read_tree('-mu', new_tree)
          system('git commit -v')
          msg "Pushing changes to remote branch #{branch}."
          git.push(remote_url, "HEAD:refs/heads/#{branch}")
        end
        FileUtils.rm_r(clone_dir)

        clear_remote(mirror, options)
      end
    end

    private

    def config_mode
      Config::MODE_READ_ONLY  # Surprisingly enough.
    end
  end
end
