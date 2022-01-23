require 'braid/version'

module Braid
  OLD_CONFIG_FILE      = '.braids'
  CONFIG_FILE          = '.braids.json'

  # See the background in the "Supported environments" section of README.md.
  #
  # The newest Git feature that Braid is currently known to rely on is
  # `receive.denyCurrentBranch = updateInstead` (in
  # spec/integration/push_spec.rb), which was added in Git 2.3.0 (in 2015).  It
  # doesn't seem worth even a small amount of work to remove that dependency and
  # support even older versions of Git.  So set that as the declared requirement
  # for now.  In general, a reasonable approach might be to try to support the
  # oldest version of Git in current "long-term support" versions of popular OS
  # distributions.
  REQUIRED_GIT_VERSION = '2.3.0'

  def self.verbose
    !!@verbose
  end

  def self.verbose=(new_value)
    @verbose = !!new_value
  end

  def self.force
    !!@force
  end

  def self.force=(new_value)
    @force = !!new_value
  end

  def self.use_local_cache
    [nil, 'true', '1'].include?(ENV['BRAID_USE_LOCAL_CACHE'])
  end

  def self.local_cache_dir
    File.expand_path(ENV['BRAID_LOCAL_CACHE_DIR'] || "#{ENV['HOME']}/.braid/cache")
  end

  class BraidError < StandardError
    def message
      value = super
      value if value != self.class.name
    end
  end

  class InternalError < BraidError
    def message
      "internal error: #{super}"
    end
  end
end

require 'braid/operations_lite'
require 'braid/operations'
require 'braid/mirror'
require 'braid/config'
require 'braid/command'
require 'braid/commands/add'
require 'braid/commands/diff'
require 'braid/commands/push'
require 'braid/commands/remove'
require 'braid/commands/setup'
require 'braid/commands/update'
require 'braid/commands/status'
require 'braid/commands/upgrade_config'
