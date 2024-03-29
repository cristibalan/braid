# Since this file can't safely depend on the Sorbet runtime, it isn't prudent to
# try to commit to `typed: true` even if the file currently passes type checking
# without needing any references to `T`.  Like `exe/braid`, this file doesn't
# have much code worth type checking.
#
# typed: false

# Braid has several entry points that run code from Ruby gems (either Braid
# itself or dependencies such as Sorbet) and expect to get the correct versions
# (either the same copy of Braid or versions of dependencies consistent with the
# gemspec or Gemfile, as applicable).  This currently applies to the following
# entry points:
#
# - The Braid CLI launcher: `exe/braid`
# - The Braid test suite under `spec`
# - The Rakefile: Has a target to run the Sorbet type checker and wants the
#   correct version for the current version of Braid.
#
# If these entry points are invoked without first activating the correct gems,
# then other globally installed versions might be used by default, leading to
# unintended behavior.  So we have each of these entry points check that a Braid
# gem is active in the current Ruby interpreter _and_ the entry point is part of
# that same Braid gem.  If so, we can assume that the correct versions of
# dependencies are active as well.
#
# To implement the check, the entry point file loads its corresponding copy of
# check_gem.rb via `require_relative`, and that copy of check_gem.rb checks that
# it is part of the active Braid gem.  Note that loading check_gem.rb via
# `require 'lib/braid/check_gem'` would defeat the purpose, since it would
# activate whatever Braid gem is visible and then check that that gem's copy of
# check_gem.rb is part of the active Braid gem (which it would always be), not
# whether the _caller_ is part of the active Braid gem.
#
# Common means of activating the correct gems before invoking an entry point
# include:
#
# - Bundler: Used when developing Braid itself and possibly by some projects
#   that use Braid.  It modifies the environment so that every Ruby subprocess
#   activates the gems from the Gemfile.lock.
# - A wrapper for `exe/braid` generated by `gem install --wrappers`.
#
# Note that we don't have every `.rb` file that is part of Braid load
# check_gem.rb: that would be too invasive and only helps in the case where a
# user manually added Braid's `lib` dir to the load path, which is a mistake
# that a reasonable user is much less likely to make than just running an entry
# point without the proper setup.
#
# TODO: Is there a more standard way to do this check?  One would think it would
# be potentially applicable to any Ruby project, though maybe most don't care as
# much as we do about catching the problem up front.

braid_spec = Gem.loaded_specs['braid']
if braid_spec.nil? || __FILE__ != braid_spec.gem_dir + '/lib/braid/check_gem.rb'
  STDERR.puts <<-MSG
Error: The RubyGems environment is not set up correctly for Braid.
- If you're using a copy of Braid installed globally via 'gem install' or
  similar, use the 'braid' wrapper script (which is typically installed at a
  location like ~/.gem/ruby/bin/braid depending on your environment) instead of
  running 'exe/braid' directly.
- If you're using a copy of Braid managed by Bundler (including when developing
  Braid itself), prepend 'bundle exec' to your command or use a binstub
  generated by 'bundle binstubs'.
MSG
  exit(1)
end
