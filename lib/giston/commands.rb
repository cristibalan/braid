module Giston
  class Commands
    def self.update(*mirrors)
      mirrors.flatten!
      if mirrors.empty?
        msg "Updating all mirrors"
        mirrors = config.mirrors if mirrors.empty?
      else
        mirrors.map! do |mirror|
          config.get(mirror)
        end

        mirrors = mirrors.compact
      end
      mirrors ||= []

      msg "No mirrors found" if mirrors.empty?

      mirrors.each do |mirror|
        update_one mirror
      end
    end

    def self.update_one(mirror)
      mirror = config.get(mirror)
      msg "Updating #{mirror["dir"]} from #{mirror["url"]}"

      svn = Giston::Svn.new(mirror["url"])
      local_revision = mirror["rev"]
      remote_revision = svn.remote_revision

      msg "Local revision: #{local_revision}. Remote revision: #{remote_revision}"

      if git.local_directory_exists?(mirror["dir"])
        if local_revision.to_i > remote_revision.to_i
          msg %(Skipping "#{mirror["dir"]} (local revision is greater than remote revision)")
          return
        end

        if local_revision.to_i == remote_revision.to_i
          msg %(Skipping "#{mirror["dir"]} (no changes between local and remote revision)")
          return
        end

        if git.local_changes?(mirror["dir"])
          msg "There are local changes in the directory you're trying to update"
          return
        end

        diff = svn.diff_file(local_revision, remote_revision)
        local.patch(diff, mirror["dir"])
        binaries = local.extract_binaries_from_diff(diff)
        binaries.each do |binary|
          svn.cat(binary, remote_revision, mirror["dir"])
        end
      else
        svn.export(mirror["dir"], remote_revision)
      end
      mirror["rev"] = remote_revision
      config.write
    rescue Giston::Git::RepositoryError => e
      msg %(giston: Skipping "#{mirror["dir"]}". Error accessing git repositry")
    rescue Giston::Svn::RepositoryNotFound => e
      msg %(giston: Skipping "#{mirror["dir"]}". Error updating from "#{mirror["url"]}")
    end

    def self.add(*args)
      url, dir, rev = self.extract_add_params(*args)
      msg "Adding mirror for #{url} in #{dir}. You must call giston update #{dir} to fetch the data."
      if config.add(url, dir, rev)
        config.write
      end
    end

    def self.remove(dir)
      msg "Removing mirror from #{dir}"
      if config.remove(dir)
        config.write
      end
    end

    def self.msg(str)
      puts "giston: " + str
    end

    private

      # buh, this sux
      # i should really learn how to use some option parser
      def self.extract_add_params(*args)
        raise if args.empty?
        url = args.slice!(0)

        case args.length
          when 0
            dir = File.basename(url)
            rev = 'HEAD'
          when 1
            dir = args[0]
            rev = 'HEAD'
          when 3
            if args[0] == '-r'
              dir = args[2]
              rev = args[1]
            end
          else
            str = "Bad params. See giston help for usage."
            msg(str)
            # raising would be smarter, but how to i test for it?
            return str
        end
        if rev == 'HEAD'
          rev = Giston::Svn.new(url).remote_revision
        end
        return *[url, dir, rev]
      end

      def self.config
        @config ||= Giston::Config.new
      end
      def self.svn
        @svn ||= Giston::Svn.new
      end
      def self.git
        @git ||= Giston::Git.new
      end
      def self.local
        @local ||= Giston::Local.new
      end

  end
end
