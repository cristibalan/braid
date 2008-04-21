begin
  require 'rubygems'
  require 'spec'
rescue LoadError
  puts <<-EOS
  To run the specs you must install the rspec gem:
    . gem install rspec
  EOS
  exit(0)
end

# all this just to change the default task
Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end
 
def remove_task(task_name)
  Rake.application.remove_task(task_name)
end

require 'spec/rake/spectask'

desc "Run the specs."
Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--options', "spec/spec.opts"]
  t.spec_files = FileList['spec/*_spec.rb']
end

remove_task :default
task :default => :spec
