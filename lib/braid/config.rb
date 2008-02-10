require 'yaml'
require 'yaml/store'

module Braid
  class Config
    attr_accessor :mirrors
    
    def initialize
      @mirrors = YAML::Store.new(".braids")
    end

    class << self
      def options_to_mirror(options = {})
        remote = options["remote"]
        branch = options["branch"] || "master"

        type   = options["type"]   || extract_type_from_path(remote)
        mirror = options["mirror"] || extract_mirror_from_path(remote)

        [mirror, {"type" => type, "remote" => remote.to_s, "branch" => branch}]
      end

      private
        def extract_type_from_path(path)
          return nil unless path
          path_scheme = path.split(":").first
          return path_scheme if %w[svn git].include? path_scheme

          return "svn" if path[-6..-1] == "/trunk"
          return "git" if path[-4..-1] == ".git"
        end
        def extract_mirror_from_path(path)
          return nil unless path
          last = File.basename(path)
          return last[0..-5] if File.extname(last) == ".git"
          last = File.basename(File.dirname(path)) if last == "trunk"
          last
        end
    end

  end
end

__END__
module Braid
  class Config
    attr_accessor :mirrors

    def initialize
      @mirrors = YAML::Store.new(".braids")
    end

    def add(mirror)
      raise MirrorNameAlreadyInUse if has_item?(mirror["dir"])
      @mirrors << mirror
      write
    end

    def remove(mirror_name)
      raise MirrorDoesNotExist unless has_item?(mirror_name)
      @mirrors.delete_if{|mirror| cleanup_dir(mirror["dir"]) == cleanup_dir(mirror_name)}
      write
    end

    def get(dir_or_mirror_hash)
      case dir_or_mirror_hash
        when String
          dir = dir_or_mirror_hash
        when Hash
          dir = dir_or_mirror_hash["dir"]
      end
      has_item?(dir) #uh, using the sideeffect. lame
    end

    def get_from_remote(remote)
      @mirrors.find{|mirror| cleanup_dir(mirror["url"]) == cleanup_dir(remote) && mirror["dir"] == extract_last_part(remote)}
    end

    def update(mirror_name, mirror)
      raise MirrorDoesNotExist unless has_item?(mirror_name)
      remove(mirror_name)
      add(mirror)
    end

    private

      def cleanup_dir(dir)
        dir.chomp("/")
      end

      # copy/paste from commands/init.rb
      def extract_last_part(path)
        last = File.basename(path)
        last = File.basename(File.dirname(path)) if last == "trunk"
        last
      end

  end
end
