require 'yaml'
require 'yaml/store'

module Braid
  class Config
    class PathAlreadyInUse < BraidError
    end
    class MirrorDoesNotExist < BraidError
    end

    def initialize(config_file = CONFIG_FILE)
      @db = YAML::Store.new(config_file)
    end

    def add_from_options(url, options)
      mirror = Mirror.new_from_options(url, options)

      add(mirror)
      mirror
    end

    def mirrors
      @db.transaction(true) do
        @db.roots
      end
    end

    def add(mirror)
      @db.transaction do
        raise PathAlreadyInUse if @db[mirror.path]
        @db[mirror.path] = clean_attributes(mirror.attributes)
      end
    end

    def get(path)
      @db.transaction(true) do
        if attributes = @db[path]
          Mirror.new(path, attributes)
        end
      end
    end

    def get!(path)
      mirror = get(path)
      raise MirrorDoesNotExist unless mirror
      mirror
    end

    def remove(mirror)
      @db.transaction do
        @db.delete(mirror.path)
      end
    end

    def update(mirror)
      @db.transaction do
        raise MirrorDoesNotExist unless @db[mirror.path]
        @db.delete(mirror)
        @db[mirror.path] = clean_attributes(mirror.attributes)
      end
    end

    private
      def clean_attributes(hash)
        (hash = hash.dup).each { |k,v| hash.delete(k) if v.nil? }
      end
  end
end
