# typed: strict

# Code to set up the Sorbet runtime and Sorbet-related utilities used throughout
# the Braid code.  Called by `lib/braid.rb` and `lib/braid/operations_lite.rb`
# before any other Braid code is loaded.

env_use_sorbet_runtime = ENV['BRAID_USE_SORBET_RUNTIME']
if env_use_sorbet_runtime == '1'
  require 'sorbet-runtime'
elsif [nil, '0'].include?(env_use_sorbet_runtime)
  require 'braid/sorbet/fake_runtime'
else
  puts <<-MSG
Braid: Error: BRAID_USE_SORBET_RUNTIME environment variable has invalid
value #{env_use_sorbet_runtime.inspect}; it must be "1", "0", or unset.
MSG
  exit(1)
end
