# -*- encoding: utf-8 -*-
require_relative 'lib/braid/version'

Gem::Specification.new do |s|
  s.name               = %q{braid}
  s.version            = Braid::VERSION
  s.platform           = Gem::Platform::RUBY

  s.authors            = ['Cristi Balan', 'Norbert Crombach', 'Peter Donald', 'Matt McCutchen']
  s.email              = %q{evil@che.lu norbert.crombach@primetheory.org peter@realityforge.org matt@mattmccutchen.net}

  s.homepage           = %q{https://github.com/cristibalan/braid}
  s.summary            = %q{A simple tool for tracking vendor branches in git.}
  s.description        = %q{A simple tool for tracking vendor branches in git.}

  # Recommendations on the web vary as to how to generate the `files` list.
  # Bundler's template for new gems
  # (https://github.com/rubygems/rubygems/blob/1e4eda741d732ca1bd7031aef0a16c7348adf7a5/bundler/lib/bundler/templates/newgem/newgem.gemspec.tt#L25-L31)
  # uses `git ls-files` in the hope of picking up all files that might be needed
  # by the gem without picking up any garbage files.  However, running Git
  # subprocesses here can be problematic in some contexts, including parts of
  # the Braid test suite that set up a custom environment in which Git
  # subprocesses invoked here would not work as intended
  # (https://github.com/cristibalan/braid/issues/107).  So we use the other
  # widely recommended approach of manually listing file globs
  # (https://guides.rubygems.org/specification-reference/#files); this should be
  # fine as long as we're careful to keep the list up to date.
  #
  # Ship only the files that are used at runtime, plus required legal notices.
  # Users who want other files should use the source repository.
  s.files              = ['LICENSE', 'exe/braid'] + Dir['lib/**/*.rb']
  s.bindir             = 'exe'
  s.executables        = ['braid']
  s.require_paths      = %w(lib)

  s.rdoc_options       = %w(--line-numbers --inline-source --title braid --main)

  s.required_ruby_version = '>= 2.5.0'
  s.add_dependency(%q<main>, ['>= 4.7.3'])
  # XXX: Minimum version?
  s.add_dependency(%q<json>)

  s.add_development_dependency(%q<rspec>, ['>= 3.4.4'])
  s.add_development_dependency(%q<mocha>, ['>= 0.9.11'])
  s.add_development_dependency(%q<rake>)
  s.add_development_dependency(%q<bundler>)
  # Helpful for Braid developers to run `bundle exec irb` for manual testing of
  # Braid internals.
  s.add_development_dependency(%q<irb>)
end
