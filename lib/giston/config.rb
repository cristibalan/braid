require 'yaml'

module Giston
  class Config
    DEFAULT_CONFIG_FILE = '.giston'
    attr_accessor :mirrors, :config_file

    def initialize(config_file = DEFAULT_CONFIG_FILE)
      @config_file = config_file
      @mirrors = []
      read
    end

    def read
      @mirrors = YAML::load_file(@config_file)
    rescue
      @mirrors = []
    end

    def reload
      @mirrors = []
      read
    end

    def write(config_file = nil)
      config_file ||= @config_file
      File.open(@config_file, 'w') do |out|
        YAML.dump(@mirrors, out)
      end 
    end

    def has_item?(dir)
      @mirrors.find{|mirror| mirror["dir"] == dir}
    end

    def get(dir_or_mirror_hash)
      case dir_or_mirror_hash
        when String
          dir = dir_or_mirror_hash
        when Hash
          dir = dir_or_mirror_hash["dir"]
      end
      has_item?(dir)
    end

    def add(url, dir, rev)
      @mirrors << {"url" => url, "dir" => dir, "rev" => rev} unless has_item?(dir)
    end

    def remove(dir)
      if has_item?(dir)
        @mirrors.delete_if{|mirror| mirror["dir"] == dir}
      end
    end

    def has_mirror_on_disk?(dir)
      File.exists?(File.join(File.dirname(config_file), dir))
    end

  end
end
