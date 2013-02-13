require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake'
require 'rspec/core/rake_task'
desc 'Run all specs'
RSpec::Core::RakeTask.new :spec  do |task|
  task.rspec_opts = %w{--backtrace}
end

desc "Test and package the gem"
task :default => [:spec, :build]
