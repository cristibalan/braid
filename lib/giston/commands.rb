module Giston
  class Command

    attr_accessor :config, :svn, :git, :local

    def initialize(options = {})
      @config = options["config"] || Giston::Config.new
      @svn    = options["svn"]    || Giston::Svn.new
      @git    = options["git"]    || Giston::Git.new
      @local  = options["local"]  || Giston::Local.new
    end

    def self.run(command, *args)
      klass = Giston::Commands.const_get(command.to_s.capitalize)
      klass.new.run(*args)
    rescue Giston::Exception => e
      puts "giston: An exception has occured: #{e.message || e} (#{e})"
    end
    
    private
      def msg(str)
        puts "giston: " + str
      end
  end
end

require 'giston/commands/init'
require 'giston/commands/fetch'
require 'giston/commands/mirror'
require 'giston/commands/forget'
require 'giston/commands/update'
