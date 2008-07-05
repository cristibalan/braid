desc "Run all specs by default"
task :default => :test
task :spec => :test

task :test do
  Dir[File.dirname(__FILE__) + '/test/**/*_spec.rb'].each do |file|
    load file
  end
end
