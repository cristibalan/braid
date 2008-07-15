require 'yaml'
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

    def get(path)
      @db.transaction(true) do
        if attributes = @db[path.to_s.sub(/\/$/, '')]
          Mirror.new(path, attributes)
        end
      end
    end

    def get!(path)
      mirror = get(path)
      raise MirrorDoesNotExist, path unless mirror
      mirror
    end

    def add(mirror)
      @db.transaction do
        raise PathAlreadyInUse, mirror.path if @db[mirror.path]
        write_mirror(mirror)
      end
    end

    def remove(mirror)
      @db.transaction do
        @db.delete(mirror.path)
      end
    end

    def update(mirror)
      @db.transaction do
        raise MirrorDoesNotExist, mirror.path unless @db[mirror.path]
        @db.delete(mirror.path)
        write_mirror(mirror)
      end
    end

    def valid?
      @db.transaction(true) do
        !@db.roots.any? do |path|
          @db[path]["url"].nil?
        end
      end
    end

    def migrate!
      @db.transaction do
        @db.roots.each do |path|
          attributes = @db[path]
          if attributes["local_branch"]
            attributes["url"] = attributes.delete("remote")
            attributes["remote"] = attributes.delete("local_branch")
            attributes["squashed"] = attributes.delete("squash")
            attributes["lock"] = attributes["revision"] # so far this has always been true
          end
          @db[path] = clean_attributes(attributes)
        end
      end
    end

    private
      def write_mirror(mirror)
        @db[mirror.path] = clean_attributes(mirror.attributes)
      end

      def clean_attributes(hash)
        hash.reject { |k,v| v.nil? }
      end
  end
end
