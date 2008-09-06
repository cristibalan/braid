require 'rake'
require 'rake/testtask'

task :default => :test

def test_task(name, pattern)
  Rake::TestTask.new(name) do |t|
    ENV['TESTOPTS'] = '--runner=s'

    t.libs << 'lib'
    t.pattern = pattern
    t.verbose = true
  end
end

test_task(:test, "test/*_test.rb")
namespace(:test) { test_task(:integration, "test/integration/*_test.rb") }
