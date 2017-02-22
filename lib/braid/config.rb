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

    def initialize(config_file = CONFIG_FILE, old_config_files = [OLD_CONFIG_FILE])
      @config_file = config_file
      (old_config_files + [config_file]).each do |file|
        next unless File.exist?(file)
        begin
          store = YAML::Store.new(file)
          @db = {}
          store.transaction(true) do
            store.roots.each do |path|
              @db[path] = store[path]
            end
          end
          return
        rescue
          @db = JSON.parse(file)
          return if @db
        end
      end
      @db = {}
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
      attributes ? Mirror.new(path, attributes) : nil
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
      write_db
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
        new_db[key].keys.each do |k|
          new_db[key].delete(k) unless Braid::Mirror::ATTRIBUTES.include?(k)
        end
      end
      File.open(@config_file, 'wb') do |f|
        f.write JSON.pretty_generate(new_db)
        f.write "\n"
      end
    end

    def clean_attributes(hash)
      hash.reject { |k, v| v.nil? }
    end
  end
end
