require 'fileutils'
require 'tmpdir'

module Braid
  module Commands
    class Push < Command
      def run(path, options = {})
        mirror = config.get!(path)

        branch = options['branch'] || mirror.branch

        setup_remote(mirror)
        mirror.fetch

        base_revision = git.rev_parse(mirror.remote)
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

        clone_dir = Dir.tmpdir + "/braid_push.#{$$}"
        Dir.mkdir(clone_dir)
        remote_url = git.remote_url(mirror.remote)
        if remote_url == mirror.cached_url
          remote_url = mirror.url
        elsif File.directory?(remote_url)
          remote_url = File.expand_path(remote_url)
        end
        Dir.chdir(clone_dir) do
          msg 'Cloning mirror with local changes.'
          git.init
          git.fetch(mirror.cached_url) if File.exist?(mirror.cached_url)
          git.fetch(remote_url, "+refs/heads/#{mirror.branch}")
          git.checkout(base_revision)
          args =[]
          args << "--directory=#{mirror.remote_path}" if mirror.remote_path
          git.apply(diff, args)
          system('git commit -v')
          msg "Pushing changes to remote branch #{branch}."
          git.push(remote_url, "HEAD:refs/heads/#{branch}")
        end
        FileUtils.rm_r(clone_dir)

        clear_remote(mirror, options)
      end
    end
  end
end
