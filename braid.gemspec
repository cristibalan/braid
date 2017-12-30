# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'braid/version'

Gem::Specification.new do |s|
  s.name               = %q{braid}
  s.version            = Braid::VERSION
  s.platform           = Gem::Platform::RUBY

  s.authors            = ['Cristi Balan', 'Norbert Crombach', 'Peter Donald']
  s.email              = %q{evil@che.lu norbert.crombach@primetheory.org peter@realityforge.org}

  s.homepage           = %q{https://github.com/cristibalan/braid}
  s.summary            = %q{A simple tool for tracking vendor branches in git.}
  s.description        = %q{A simple tool for tracking vendor branches in git.}

  s.rubyforge_project  = %q{braid}

  s.files              = `git ls-files`.split("\n")
  s.test_files         = `git ls-files -- {spec}/*`.split("\n")
  s.executables        = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.default_executable = %q{braid}
  s.require_paths      = %w(lib)

  s.has_rdoc           = false
  s.rdoc_options       = %w(--line-numbers --inline-source --title braid --main)

  s.required_ruby_version = '>= 2.2.0'
  s.add_dependency(%q<main>, ['>= 4.7.3'])
  # XXX: Minimum version?
  s.add_dependency(%q<json>)

  s.add_development_dependency(%q<rspec>, ['>= 3.4.4'])
  s.add_development_dependency(%q<mocha>, ['>= 0.9.11'])
  s.add_development_dependency(%q<rake>)
  s.add_development_dependency(%q<bundler>)
end
