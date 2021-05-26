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
		  git.config(['--local', 'filter.lfs.smudge', "\"git-lfs smudge --skip %f\"" ])
          git.config(['--local', 'filter.lfs.process', "\"git-lfs filter-process --skip\""])
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
          git.checkout(base_revision)
          git.rm_r(mirror.remote_path || '.')
          git.add_item_to_index(local_mirror_item, mirror.remote_path || '', true)
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
