require 'yaml'
require 'yaml/store'

module Braid
  class Config
    attr_accessor :db
    
    def initialize(config_file = ".braids")
      @db = YAML::Store.new(config_file)
    end

    def add_from_options(remote, options)
      mirror, params = self.class.options_to_mirror(remote, options)

      raise Braid::Config::RemoteIsRequired unless params["remote"]
      raise Braid::Config::MirrorTypeIsRequired unless params["type"]
      raise Braid::Config::BranchIsRequired unless params["branch"]
      raise Braid::Config::MirrorNameIsRequired unless mirror

      add(mirror, params)
      [mirror, get(mirror)]
    end

    def mirrors
      @db.transaction do
        @db.roots
      end
    end

    def add(mirror, params)
      mirror = remove_trailing_slash(mirror)
      @db.transaction do
        raise Braid::Config::MirrorNameAlreadyInUse if @db[mirror]
        @db[mirror] = params.merge("remote" => remove_trailing_slash(params["remote"]))
      end
    end

    def get(mirror)
      mirror = remove_trailing_slash(mirror)
      @db.transaction do
        @db[mirror]
      end
    end

    def get_by_remote(remote)
      remote = remove_trailing_slash(remote)
      mirror = nil
      @db.transaction do
        mirror = @db.roots.detect { |mirror| @db[mirror]["remote"] == remote }
      end
      [mirror, get(mirror)]
    end

    def remove(mirror)
      mirror = remove_trailing_slash(mirror)
      @db.transaction do
        @db.delete(mirror)
      end
    end

    def update(mirror, params)
      mirror = remove_trailing_slash(mirror)
      @db.transaction do
        raise Braid::Config::MirrorDoesNotExist unless @db[mirror]
        tmp = @db[mirror].merge(params)
        @db[mirror] = tmp.merge("remote" => remove_trailing_slash(tmp["remote"]))
      end
    end

    def replace(mirror, params)
      mirror = remove_trailing_slash(mirror)
      @db.transaction do
        raise Braid::Config::MirrorDoesNotExist unless @db[mirror]
        params["remote"] = remove_trailing_slash(params["remote"]) if params["remote"]
        @db[mirror] = params
      end
    end

    class << self
      def options_to_mirror(remote, options = {})
        remote = remove_trailing_slash(remote)
        branch = options["branch"] || "master"

        type   = options["type"]   || extract_type_from_path(remote)
        mirror = options["mirror"] || extract_mirror_from_path(remote)

        [remove_trailing_slash(mirror), {"type" => type, "remote" => remote, "branch" => branch}]
      end

      private

        def extract_type_from_path(path)
          return nil unless path
          path = remove_trailing_slash(path)
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
        # usage of this method is horrible and there are no specs :/
        def remove_trailing_slash(path)
          path.chomp("/") rescue path
        end
    end

    private

      def remove_trailing_slash(path)
        path.chomp("/") rescue path
      end

  end
end
