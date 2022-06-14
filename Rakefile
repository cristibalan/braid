require_relative 'lib/braid/check_gem'

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake'
require 'rspec/core/rake_task'
desc 'Run all specs'
RSpec::Core::RakeTask.new :spec  do |task|
  task.rspec_opts = %w{--backtrace}
end

# Define the `srb` target based on whether the Sorbet static analyzer is
# available, which is OS-dependent (see development.md).
require 'rubygems'
begin
  srb_path = Gem.bin_path('sorbet', 'srb')
  desc 'Typecheck with Sorbet'
  task :srb do
    system(srb_path, 'tc', exception: true)
  end
  task :default => [:srb]
rescue Gem::Exception
  desc 'Typecheck with Sorbet (unavailable)'
  task :srb do
    raise StandardError, 'The Sorbet static analyzer is not available.'
  end
  # Don't add a dependency from :default to :srb .
end

desc 'Test and package the gem'
task :default => [:spec, :build]
