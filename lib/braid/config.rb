# typed: true
require 'yaml'
require 'json'
require 'yaml/store'
require 'braid/sorbet/setup'

# Some info about the configuration versioning design:
# https://github.com/cristibalan/braid/issues/66#issuecomment-354211311
#
# Current configuration format:
# ```
# {
#   "config_version": 1,
#   "mirrors": {
#     <mirror path: string>: {
#       "url": <upstream URL: string>,
#       "path": <remote path: string>,
#       "branch": <upstream branch: string>,
#       "tag": <upstream tag: string>,
#       "revision": <current upstream revision: string>
#     }
#   }
# }
# ```
#
# History of configuration formats understood by current Braid:
#
# - Braid 1.1.0, config_version 1:
#   - "config_version" introduced; mirrors moved to "mirrors"
#   - Single-file mirrors (f340b0c)
# - Braid 1.0.18:
#   - Locked mirrors indicated by absence of "branch" and "tag" attributes, not
#     presence of "lock" attribute (e6535aa)
# - Braid 1.0.17:
#   - Support for full-history mirrors ("squashed": false) removed; "squashed"
#     attribute no longer written (eb72030)
# - Braid 1.0.11:
#   - "remote" attribute no longer written (f8fd088)
# - Braid 1.0.9:
#   - .braids -> .braids.json (6806c61)
# - Braid 1.0.0:
#   - YAML -> JSON (9d3fa11)
#   - Support for Subversion mirrors removed ("type": "svn") removed (9d8d390)
#
#
# (Entries that predate the creation of this list have commit IDs for reference.
# Of course, when adding a new entry, you can't add the commit ID in the same
# commit, but you don't need to because people can just run `git log` on this
# file.)

module Braid
  class Config
    extend T::Sig

    # TODO (typing): Migrate to T::Enum?
    ConfigMode = T.type_alias { Integer }

    MODE_UPGRADE = 1
    MODE_READ_ONLY = 2
    MODE_MAY_WRITE = 3

    CURRENT_CONFIG_VERSION = 1

    class PathAlreadyInUse < BraidError
      sig {returns(String)}
      def message
        "path already in use: #{super}"
      end
    end
    class MirrorDoesNotExist < BraidError
      sig {returns(String)}
      def message
        "mirror does not exist: #{super}"
      end
    end

    class RemoveMirrorDueToBreakingChange < StandardError
    end

    # For upgrade-config command only.  XXX: Ideally would be immutable.
    sig {returns(Integer)}
    attr_reader :config_version
    sig {returns(T::Boolean)}
    attr_reader :config_existed
    sig {returns(T::Array[String])}
    attr_reader :breaking_change_descs

    # options: config_file, old_config_files, mode
    sig {params(options: T.untyped).void}
    def initialize(options = {})
      @config_file     = options['config_file']      || CONFIG_FILE
      old_config_files = options['old_config_files'] || [OLD_CONFIG_FILE]
      @mode            = options['mode']             || MODE_MAY_WRITE

      data = load_config(@config_file, old_config_files)
      @config_existed = !data.nil?
      if !@config_existed
        @config_version = CURRENT_CONFIG_VERSION
        @db = {}
      elsif data['config_version'].is_a?(Numeric)
        @config_version = data['config_version']
        @db = data['mirrors']
      else
        # Before config versioning (Braid < 1.1.0)
        @config_version = 0
        @db = data
      end

      if @config_version > CURRENT_CONFIG_VERSION
        raise BraidError, <<-MSG
This version of Braid (#{VERSION}) is too old to understand your project's Braid
configuration file (version #{@config_version}).  See the instructions at
https://cristibalan.github.io/braid/config_versions.html to install and use a
compatible newer version of Braid.
MSG
      end

      # In all modes, instantiate all mirrors to scan for breaking changes.
      @breaking_change_descs = []
      paths_to_delete = []
      @db.each do |path, attributes|
        begin
          mirror = Mirror.new(path, attributes,
            lambda {|desc| @breaking_change_descs.push(desc)})
          # In MODE_UPGRADE, update @db now.  In other modes, we won't write the
          # config if an upgrade is needed, so it doesn't matter that we don't
          # update @db.
          #
          # It's OK to change the values of existing keys during iteration:
          # https://groups.google.com/d/msg/comp.lang.ruby/r5OI6UaxAAg/SVpU0cktmZEJ
          write_mirror(mirror) if @mode == MODE_UPGRADE
        rescue RemoveMirrorDueToBreakingChange
          # I don't know if deleting during iteration is well-defined in all
          # Ruby versions we support, so defer the deletion.
          # ~ matt@mattmccutchen.net, 2017-12-31
          paths_to_delete.push(path) if @mode == MODE_UPGRADE
        end
      end
      paths_to_delete.each do |path|
        @db.delete(path)
      end

      if @mode != MODE_UPGRADE && !@breaking_change_descs.empty?
        raise BraidError, <<-MSG
This version of Braid (#{VERSION}) no longer supports a feature used by your
Braid configuration file (version #{@config_version}).  Run 'braid upgrade-config --dry-run'
for information about upgrading your configuration file, or see the instructions
at https://cristibalan.github.io/braid/config_versions.html to install and run a
compatible older version of Braid.
MSG
      end

      if @mode == MODE_MAY_WRITE && @config_version < CURRENT_CONFIG_VERSION
        raise BraidError, <<-MSG
This command may need to write to your Braid configuration file,
but this version of Braid (#{VERSION}) cannot write to your configuration file
(currently version #{config_version}) without upgrading it to configuration version #{CURRENT_CONFIG_VERSION},
which would force other developers on your project to upgrade Braid.  Run
'braid upgrade-config' to proceed with the upgrade, or see the instructions at
https://cristibalan.github.io/braid/config_versions.html to install and run a
compatible older version of Braid.
MSG
      end

    end

    sig {params(url: String, options: TODO_TYPE).returns(Mirror)}
    def add_from_options(url, options)
      mirror = Mirror.new_from_options(url, options)

      add(mirror)
      mirror
    end

    sig {returns(T::Array[Mirror])}
    def mirrors
      @db.keys
    end

    sig {params(path: String).returns(T.nilable(Mirror))}
    def get(path)
      key = path.to_s.sub(/\/$/, '')
      attributes = @db[key]
      attributes ? Mirror.new(path, attributes) : nil
    end

    sig {params(path: String).returns(Mirror)}
    def get!(path)
      mirror = get(path)
      raise MirrorDoesNotExist, path unless mirror
      mirror
    end

    sig {params(mirror: Mirror).void}
    def add(mirror)
      raise PathAlreadyInUse, mirror.path if get(mirror.path)
      write_mirror(mirror)
      write_db
    end

    sig {params(mirror: Mirror).void}
    def remove(mirror)
      @db.delete(mirror.path)
      write_db
    end

    sig {params(mirror: Mirror).void}
    def update(mirror)
      raise MirrorDoesNotExist, mirror.path unless get(mirror.path)
      write_mirror(mirror)
      write_db
    end

    # Public for upgrade-config command only.
    sig {void}
    def write_db
      new_db = {}
      @db.keys.sort.each do |key|
        new_db[key] = {}
        Braid::Mirror::ATTRIBUTES.each do |k|
          new_db[key][k] = @db[key][k] if @db[key].has_key?(k)
        end
      end
      new_data = {
        'config_version' => CURRENT_CONFIG_VERSION,
        'mirrors' => new_db
      }
      File.open(@config_file, 'wb') do |f|
        f.write JSON.pretty_generate(new_data)
        f.write "\n"
      end
    end

    private

    sig {params(config_file: String, old_config_files: T::Array[String]).returns(TODO_TYPE)}
    def load_config(config_file, old_config_files)
      (old_config_files + [config_file]).each do |file|
        next unless File.exist?(file)
        begin
          store = T.let(YAML::Store, T.untyped).new(file)
          data = {}
          store.transaction(true) do
            store.roots.each do |path|
              data[path] = store[path]
            end
          end
          return data
        rescue
          data = JSON.parse(file)
          return data if data
        end
      end
      nil
    end

    sig {params(mirror: Mirror).void}
    def write_mirror(mirror)
      @db[mirror.path] = clean_attributes(mirror.attributes)
    end

    sig {params(hash: T::Hash[String, TODO_TYPE]).returns(T::Hash[String, TODO_TYPE])}
    def clean_attributes(hash)
      hash.reject { |_, v| v.nil? }
    end
  end
end
