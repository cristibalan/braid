module Giston
  module Commands
    class Update < Giston::Command
      def run(mirror_name=nil, revision=nil)
        mirror_name ? update_one(mirror_name, revision) : update_all
      end

      private
        def update_all
          config.mirrors.each do |mirror|
            update_one(mirror["dir"])
          end
        end

        def update_one(mirror_name, new_revision=nil)
          mirror = config.get(mirror_name)
          local_revision = mirror["rev"]
          remote_revision = svn.remote_revision(mirror["url"])
          new_revision ||= remote_revision
          remote = mirror["url"]

          raise RequestedRevisionIsHigherThanRemoteRevision      if new_revision.to_i   >  remote_revision.to_i
          raise LocalRevisionIsHigherThanRequestedRevision       if local_revision.to_i >  new_revision.to_i
          raise MirrorAlreadyUpToDate                            if local_revision.to_i == new_revision.to_i
          raise Giston::Git::LocalRepositoryHasUncommitedChanges if git.local_changes?(mirror["dir"])

          diff = svn.diff_file(remote, local_revision, new_revision)
          local.patch(diff, mirror_name)

          binaries = local.extract_binaries_from_diff(diff)
          binaries.each do |binary|
            svn.cat(remote, binary, new_revision, mirror_name)
          end

          mirror["rev"] = new_revision
          config.update(mirror_name, mirror)
        end

    end
  end
end
