Gem::Specification.new do |s|
  s.name = %q{braid}
  s.version = "0.4.9"

  s.specification_version = 2 if s.respond_to? :specification_version=

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Cristi Balan", "Norbert Crombach"]
  s.date = %q{2008-05-01}
  s.default_executable = %q{braid}
  s.description = %q{A simple tool for tracking vendor branches in git.}
  s.email = %q{evil@che.lu}
  s.executables = ["braid"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc", "LICENSE", "Rakefile", "braid.gemspec", "bin/braid", "lib/braid.rb", "lib/braid/command.rb", "lib/braid/commands/add.rb", "lib/braid/commands/diff.rb", "lib/braid/commands/remove.rb", "lib/braid/commands/setup.rb", "lib/braid/commands/update.rb", "lib/braid/config.rb", "lib/braid/mirror.rb", "lib/braid/operations.rb", "test/braid_spec.rb", "test/config_spec.rb", "test/mirror_spec.rb", "test/operations_spec.rb", "test/test_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://evil.che.lu/projects/braid}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "braid", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{braid}
  s.rubygems_version = %q{1.1.0}
  s.summary = %q{A simple tool for tracking vendor branches in git.}

  s.add_dependency(%q<main>, [">= 2.8.0"])
  s.add_dependency(%q<open4>, [">= 0.9.6"])
end
