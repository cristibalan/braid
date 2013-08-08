require 'yaml'
require 'json'
require 'yaml/store'

module Braid
  class Config
    class PathAlreadyInUse < BraidError
      def message
        "path already in use: #{super}"
      end
    end
    class MirrorDoesNotExist < BraidError
      def message
        "mirror does not exist: #{super}"
      end
    end

    def initialize(config_file = CONFIG_FILE)
      @config_file = config_file
      begin
        store = YAML::Store.new(@config_file)
        @db = {}
        store.transaction(true) do
          store.roots.each do |path|
            @db[path] = store[path]
          end
        end
      rescue
        @db = JSON.parse(@config_file)
      end
    end

    def add_from_options(url, options)
      mirror = Mirror.new_from_options(url, options)

      add(mirror)
      mirror
    end

    def mirrors
      @db.keys
    end

    def get(path)
      key = path.to_s.sub(/\/$/, '')
      attributes = @db[key]
      return attributes ? Mirror.new(path, attributes) : nil
    end

    def get!(path)
      mirror = get(path)
      raise MirrorDoesNotExist, path unless mirror
      mirror
    end

    def add(mirror)
      raise PathAlreadyInUse, mirror.path if get(mirror.path)
      write_mirror(mirror)
    end

    def remove(mirror)
      @db.delete(mirror.path)
    end

    def update(mirror)
      raise MirrorDoesNotExist, mirror.path unless get(mirror.path)
      @db.delete(mirror.path)
      write_mirror(mirror)
    end

    private
    def write_mirror(mirror)
      @db[mirror.path] = clean_attributes(mirror.attributes)
      write_db
    end

    def write_db
      new_db = {}
      @db.keys.sort.each do |key|
        new_db[key] = @db[key]
      end
      File.open(@config_file, "wb") { |f| f.write JSON.pretty_generate(new_db) }
    end

    def clean_attributes(hash)
      hash.reject { |k, v| v.nil? }
    end
  end
end
