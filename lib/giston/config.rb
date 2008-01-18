require 'yaml'

module Giston
  class Config
    DEFAULT_CONFIG_FILE = '.giston'
    attr_accessor :mirrors

    def initialize(config_file = DEFAULT_CONFIG_FILE)
      @config_file = config_file
      read
    end

    def read
      @mirrors = YAML::load_file(@config_file)
    rescue
      @mirrors = []
    end

    def write(config_file = nil)
      config_file ||= @config_file
      File.open(@config_file, 'w') do |out|
        YAML.dump(@mirrors, out)
      end 
    end

    def has_item?(mirror_name)
      @mirrors.find{|mirror| cleanup_dir(mirror["dir"]) == cleanup_dir(mirror_name)}
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
