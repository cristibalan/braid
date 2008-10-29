Gem::Specification.new do |s|
  s.name = %q{braid}
  s.version = "0.5"

  s.specification_version = 2 if s.respond_to? :specification_version=

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Cristi Balan", "Norbert Crombach"]
  s.date = %q{2008-10-29}
  s.default_executable = %q{braid}
  s.description = %q{A simple tool for tracking vendor branches in git.}
  s.email = %q{evil@che.lu}
  s.executables = ["braid"]
  s.files = ["bin/braid", "braid.gemspec", "lib/braid/command.rb", "lib/braid/commands/add.rb", "lib/braid/commands/diff.rb", "lib/braid/commands/remove.rb", "lib/braid/commands/setup.rb", "lib/braid/commands/update.rb", "lib/braid/config.rb", "lib/braid/mirror.rb", "lib/braid/operations.rb", "lib/braid.rb", "LICENSE", "Rakefile", "README.textile", "test/braid_test.rb", "test/config_test.rb", "test/fixtures/shiny/README", "test/fixtures/skit1/layouts/layout.liquid", "test/fixtures/skit1/preview.png", "test/fixtures/skit1.1/layouts/layout.liquid", "test/fixtures/skit1.2/layouts/layout.liquid", "test/integration/adding_test.rb", "test/integration/updating_test.rb", "test/integration_helper.rb", "test/mirror_test.rb", "test/operations_test.rb", "test/test_helper.rb"]
  s.has_rdoc = false
  s.homepage = %q{http://evil.che.lu/projects/braid}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "braid", "--main"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{braid}
  s.rubygems_version = %q{1.1.0}
  s.summary = %q{A simple tool for tracking vendor branches in git.}

  s.add_dependency(%q<main>, [">= 2.8.0"])
  s.add_dependency(%q<open4>, [">= 0.9.6"])
end
