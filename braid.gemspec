Gem::Specification.new do |s|
  s.name = %q{braid}
  s.version = "0.3.4"

  s.specification_version = 2 if s.respond_to? :specification_version=

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Cristi Balan", "Norbert Crombach"]
  s.date = %q{2008-04-25}
  s.default_executable = %q{braid}
  s.description = %q{Braid is a simple tool to help track git and svn vendor branches in a git repository}
  s.email = %q{evil@che.lu}
  s.executables = ["braid"]
  s.extra_rdoc_files = ["History.txt", "License.txt", "Manifest.txt", "README.txt", "TODO.txt"]
  s.files = ["History.txt", "License.txt", "Manifest.txt", "README.txt", "Rakefile", "TODO.txt", "bin/braid", "config/hoe.rb", "config/requirements.rb", "lib/braid.rb", "lib/braid/commands.rb", "lib/braid/commands/add.rb", "lib/braid/commands/diff.rb", "lib/braid/commands/remove.rb", "lib/braid/commands/setup.rb", "lib/braid/commands/update.rb", "lib/braid/config.rb", "lib/braid/exceptions.rb", "lib/braid/operations.rb", "lib/braid/version.rb", "braid.gemspec", "script/destroy", "script/generate", "setup.rb", "spec/braid_spec.rb", "spec/config_spec.rb", "spec/operations_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "tasks/deployment.rake", "tasks/environment.rake", "tasks/rspec.rake", "tasks/website.rake"]
  s.has_rdoc = true
  s.homepage = %q{http://evil.che.lu/projects/braid}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{braid}
  s.rubygems_version = %q{1.1.0}
  s.summary = %q{Braid is a simple tool to help track git and svn vendor branches in a git repository}

  s.add_dependency(%q<main>, [">= 2.8.0"])
  s.add_dependency(%q<open4>, [">= 0.9.6"])
end
