require 'yaml'
require 'yaml/store'

module Braid
  class Config
    attr_accessor :mirrors
    
    def initialize(config_file = ".braids")
      @mirrors = YAML::Store.new(config_file)
    end

    def add(mirror, params)
      mirror = remove_trailing_slash(mirror)
      @mirrors.transaction do
        raise Braid::Config::MirrorNameAlreadyInUse if @mirrors[mirror]
        @mirrors[mirror] = params.merge("remote" => remove_trailing_slash(params["remote"]))
      end
    end

    def get(mirror)
      mirror = remove_trailing_slash(mirror)
      @mirrors.transaction do
        @mirrors[mirror]
      end
    end

    def get_by_remote(remote)
      remote = remove_trailing_slash(remote)
      mirror = nil
      @mirrors.transaction do
        mirror = @mirrors.roots.detect { |mirror| @mirrors[mirror]["remote"] == remote }
      end
      [mirror, get(mirror)]
    end

    def remove(mirror)
      mirror = remove_trailing_slash(mirror)
      @mirrors.transaction do
        @mirrors.delete(mirror)
      end
    end

    def update(mirror, params)
      mirror = remove_trailing_slash(mirror)
      @mirrors.transaction do
        raise Braid::Config::MirrorDoesNotExist unless @mirrors[mirror]
        tmp = @mirrors[mirror].merge(params)
        @mirrors[mirror] = tmp.merge("remote" => remove_trailing_slash(tmp["remote"]))
      end
    end

    def replace(mirror, params)
      mirror = remove_trailing_slash(mirror)
      @mirrors.transaction do
        raise Braid::Config::MirrorDoesNotExist unless @mirrors[mirror]
        params["remote"] = remove_trailing_slash(params["remote"]) if params["remote"]
        @mirrors[mirror] = params
      end
    end

    class << self
      def options_to_mirror(options = {})
        remote = options["remote"]
        branch = options["branch"] || "master"

        type   = options["type"]   || extract_type_from_path(remote)
        mirror = options["mirror"] || extract_mirror_from_path(remote)

        [remove_trailing_slash(mirror), {"type" => type, "remote" => remove_trailing_slash(remote.to_s), "branch" => branch}]
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
