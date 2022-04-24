# typed: strict

require 'braid/sorbet/setup'
require 'braid/version'

module Braid
  extend T::Sig

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

  @verbose = T.let(false, T::Boolean)

  sig {returns(T::Boolean)}
  def self.verbose
    !!@verbose
  end

  # TODO (typing): One would think `new_value` shouldn't be nilable, but
  # apparently `lib/braid/main.rb` passes nil sometimes. Is that easy to fix?
  # (Ditto with `self.force=` below.)
  sig {params(new_value: T.nilable(T::Boolean)).void}
  def self.verbose=(new_value)
    @verbose = !!new_value
  end

  @force = T.let(false, T::Boolean)

  sig {returns(T::Boolean)}
  def self.force
    !!@force
  end

  sig {params(new_value: T.nilable(T::Boolean)).void}
  def self.force=(new_value)
    @force = !!new_value
  end

  sig {returns(T::Boolean)}
  def self.use_local_cache
    [nil, 'true', '1'].include?(ENV['BRAID_USE_LOCAL_CACHE'])
  end

  sig {returns(String)}
  def self.local_cache_dir
    File.expand_path(ENV['BRAID_LOCAL_CACHE_DIR'] || "#{ENV['HOME']}/.braid/cache")
  end

  class BraidError < StandardError
    extend T::Sig
    sig {returns(String)}
    def message
      value = super
      value if value != self.class.name
    end
  end

  class InternalError < BraidError
    sig {returns(String)}
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
