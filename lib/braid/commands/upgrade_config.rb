# typed: strict
module Braid
  module Commands
    class UpgradeConfig < Command
      class Options < T::Struct
        prop :dry_run, T::Boolean
        prop :allow_breaking_changes, T::Boolean
      end

      sig {params(options: Options).void}
      def initialize(options)
        @options = options
      end

      private

      sig {returns(Config::ConfigMode)}
      def config_mode
        Config::MODE_UPGRADE
      end

      sig {void}
      def run_internal
        # Config loading in MODE_UPGRADE will bail out only if the config
        # version is too new.

        if !config.config_existed
          puts <<-MSG
Your repository has no Braid configuration file.  It will be created with the
current configuration version when you add the first mirror.
MSG
          return
        elsif config.config_version == Config::CURRENT_CONFIG_VERSION
          puts <<-MSG
Your configuration file is already at the current configuration version (#{Config::CURRENT_CONFIG_VERSION}).
MSG
          return
        end

        puts <<-MSG
Your configuration file will be upgraded from configuration version #{config.config_version} to #{Config::CURRENT_CONFIG_VERSION}.
Other developers on your project will need to use a Braid version compatible
with configuration version #{Config::CURRENT_CONFIG_VERSION}; see
https://cristibalan.github.io/braid/config_versions.html .

MSG

        unless config.breaking_change_descs.empty?
          puts <<-MSG
The following breaking changes will occur:
#{config.breaking_change_descs.join('')}
MSG
        end

        if @options.dry_run
          puts <<-MSG
Run 'braid upgrade-config#{config.breaking_change_descs.empty? ? '' : ' --allow-breaking-changes'}' to perform the upgrade.
MSG
        elsif !config.breaking_change_descs.empty? && !@options.allow_breaking_changes
          raise BraidError, 'You must pass --allow-breaking-changes to accept the breaking changes.'
        else
          config.write_db
          add_config_file
          had_changes = git.commit('Upgrade configuration')
          raise InternalError, 'upgrade-config had no changes??' unless had_changes
          msg 'Configuration upgrade complete.'
        end
      end
    end
  end
end
