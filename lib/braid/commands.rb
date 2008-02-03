module Braid
  class Command

    attr_accessor :config, :svn, :git, :local

    def initialize(options = {})
      @config = options["config"] || Braid::Config.new
      @svn    = options["svn"]    || Braid::Svn.new
      @git    = options["git"]    || Braid::Git.new
      @local  = options["local"]  || Braid::Local.new
    end

    def self.run(command, *args)
      klass = Braid::Commands.const_get(command.to_s.capitalize)
      klass.new.run(*args)
    rescue Braid::Exception => e
      puts "braid: An exception has occured: #{e.message || e} (#{e})"
    end
    
    private
      def msg(str)
        puts "braid: " + str
      end
  end
end

require 'braid/commands/init'
require 'braid/commands/fetch'
require 'braid/commands/mirror'
require 'braid/commands/forget'
require 'braid/commands/update'
