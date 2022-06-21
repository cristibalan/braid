source 'https://rubygems.org'

gemspec

# Dependencies for Sorbet type checking.  See the "Type checking" section of
# development.md for background.

# According to https://sorbet.org/docs/faq#how-do-i-upgrade-sorbet, Sorbet may
# make breaking changes at any time, so we pin a version here that we believe
# works with the current version of Braid.  If we checked in Gemfile.lock, we
# may be able to rely on it to pin the version instead.  Feel free to upgrade
# Sorbet if you can fix any new type errors and the IDE features still seem to
# work.
SORBET_VERSION_SPEC = '= 0.5.10101'

# We want developers on OSes supported by `sorbet-static` to be able to get in
# their bundle, but we also need to be able to run the test suite on OSes
# supported by Braid that don't have `sorbet-static`, which means we need to be
# able to run `bundle install` successfully.  I can think of two basic
# approaches to achieve this:
#
# 1. Hard-code the list of OSes on which to install `sorbet-static` here.
#
# 2. Have some way for the user to manually opt in or out of installing
#    `sorbet-static`.
#
# (1) saves the user a step but has the obvious disadvantage that the list of
# OSes here could be wrong or out of date.  Furthermore, Gemfile platforms are
# different from RubyGems platforms and I couldn't find a way to express "Linux
# and not Windows RubyInstaller" using Gemfile platforms; `ruby` did not work,
# contrary to the documentation
# (https://bundler.io/man/gemfile.5.html#PLATFORMS).  So we'd have to determine
# the Ruby platform using RUBY_PLATFORM, which always returns the host platform
# and doesn't work for "cross-bundling", but I don't think we care about
# cross-bundling.
#
# The obvious mechanism for (2), namely a group in the Gemfile, doesn't solve
# the problem because turning off a group only turns off _installation_ of the
# gems; Bundler still requires that suitable gems be _available_.  So if we
# wanted to do (2), we'd have to invent an ad-hoc mechanism such as our own
# configuration file.
#
# Given all this, the least evil seems to be to do (1) using RUBY_PLATFORM. This
# is all for a Gemfile-level dependency.  Adding a platform-conditional
# gemspec-level dependency is apparently also possible but much trickier
# (https://stackoverflow.com/questions/4596606/rubygems-how-do-i-add-platform-specific-dependency).
#
# Since we want to use the same version of `sorbet-static` and `sorbet-runtime`,
# it's convenient to make `sorbet-runtime` a Gemfile-level dependency too rather
# than find a way to define the version in one place and reference it in both
# the gemspec and the Gemfile.  Not having `sorbet-runtime` as a gemspec-level
# dependency doesn't seem like a great loss; see
# https://stackoverflow.com/questions/41245385/what-are-the-practical-advantages-of-using-add-development-dependency-in-gems.
#
# TODO: Since this problem affects any Ruby project that uses Sorbet and
# supports Windows, Sorbet should offer a standard solution, such as a
# Sorbet-provided gem that does the complicated platform-conditional dependency
# trick for us.  File a Sorbet enhancement request?
#
# ~ Matt 2022-04-03

group :development do
  gem 'sorbet-runtime', SORBET_VERSION_SPEC

  # Note: `install_if` is supported only by Bundler and not by `gem install -g`,
  # which users may prefer due to its `--conservative` option (for which Bundler
  # doesn't seem to have an analogue), so we use a plain Ruby `if` instead.
  #
  if %w(arm64-darwin21 x86_64-linux).include?(RUBY_PLATFORM)
    # Note: `sorbet-static` is the OS-dependent component, while `sorbet` is a
    # plain-Ruby wrapper with some additional functionality we need.
    gem 'sorbet', SORBET_VERSION_SPEC
  end
end
