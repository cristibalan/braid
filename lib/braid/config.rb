require 'yaml'
require 'yaml/store'

module Braid
  class Config
    attr_accessor :db
    
    def initialize(config_file = nil)
      config_file ||= CONFIG_FILE
      @db = YAML::Store.new(config_file)
    end

    def add_from_options(remote, options)
      mirror, params = self.class.options_to_mirror(remote, options)

      raise Braid::Config::RemoteIsRequired unless params["remote"]
      raise Braid::Config::MirrorTypeIsRequired unless params["type"]
      raise Braid::Config::BranchIsRequired unless params["type"] == "svn" || params["branch"]
      raise Braid::Config::MirrorNameIsRequired unless mirror
      raise Braid::Config::UnknownMirrorType unless MIRROR_TYPES.include?(params["type"])

      params.delete("rails_plugin")
      params.delete("branch") if params["type"] == "svn"
      add(mirror, params)
      [mirror, get(mirror)]
    end

    def mirrors
      @db.transaction(true) do
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
      @db.transaction(true) do
        @db[mirror]
      end
    end

    def get!(mirror)
      params = get(mirror)
      raise Braid::Config::MirrorDoesNotExist unless params
      params
    end

    def get_by_remote(remote)
      remote = remove_trailing_slash(remote)
      mirror = nil
      @db.transaction(true) do
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

    def self.options_to_mirror(remote, options = {})
      remote = remove_trailing_slash(remote)
      branch = options["branch"] || "master"

      if options["type"]
        type = options["type"]
      else
        type = extract_type_from_path(remote)
        raise Braid::Config::CannotGuessMirrorType unless type
      end

      mirror = options["mirror"] || extract_mirror_from_path(remote)

      if options["rails_plugin"]
        mirror = "vendor/plugins/#{mirror}"
      end

      squash = !options["full"]

      [remove_trailing_slash(mirror), { "type" => type, "remote" => remote, "branch" => branch, "squash" => squash }]
    end

    private
      def remove_trailing_slash(path)
        self.class.send(:remove_trailing_slash, path)
      end

      def self.remove_trailing_slash(path)
        # bluh.
        path.sub(/\/$/, '')
      end

      def self.extract_type_from_path(path)
        return nil unless path
        path = remove_trailing_slash(path)

        # check for git:// and svn:// URLs
        path_scheme = path.split(":").first
        return path_scheme if %w[git svn].include?(path_scheme)

        return "svn" if path[-6..-1] == "/trunk"
        return "git" if path[-4..-1] == ".git"
      end

      def self.extract_mirror_from_path(path)
        return nil unless path
        name = File.basename(path)

        if File.extname(name) == ".git"
          # strip .git
          name[0..-5]
        elsif name == "trunk"
          # use parent
          File.basename(File.dirname(path))
        else
          name
        end
      end
  end
end
