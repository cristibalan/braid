require 'fileutils'
require 'tmpdir'

module Braid
  module Commands
    class Push < Command
      def run(path, options = {})
        mirror        = config.get!(path)

        #mirror.fetch

        base_revision = git.rev_parse(mirror.remote)
        unless mirror.merged?(base_revision)
          msg "Mirror is not up to date. Stopping."
          return
        end

        diff = mirror.diff
        if diff.empty?
          msg "No local changes found. Stopping."
          return
        end

        clone_dir = Dir.tmpdir + "/braid_push.#{$$}"
        Dir.mkdir(clone_dir)
        source_dir = Dir.pwd
        remote_url = git.remote_url(mirror.remote)
        if remote_url == mirror.cached_url
          remote_url = mirror.url
        elsif File.directory?(remote_url)
          remote_url = File.expand_path(remote_url)
        end
        Dir.chdir(clone_dir) do
          msg "Cloning mirror with local changes."
          git.init
          git.fetch(source_dir)
          git.fetch(remote_url)
          git.checkout(base_revision)
          git.apply(diff)
          system("git commit -v")
          msg "Pushing changes to remote."
          git.push(remote_url, "HEAD:#{mirror.branch}")
        end
        FileUtils.rm_r(clone_dir)
      end
    end
  end
end
