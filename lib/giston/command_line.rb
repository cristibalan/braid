module Giston
  class CommandLine
    HALP = <<EOD
  Usage: giston cmd [paths]

  Examples:

    giston update local/dir

      Updates the giston mirror found in local/dir to the latest version available in svn.

    giston update

      Updates all the giston mirrors.

    giston add svn://path/to/svn/repo local/dir [-r REVISION]

      Adds a giston mirror of a svn repository path to a local/dir in .giston.
      You must run giston update local/dir to fetch the data.

    giston remove local/dir

      Removes a giston mirror for local/dir.
      You must manually remove the directory afterwards.

    giston help, giston --help, giston -h
      
      Shows this message

    giston --version, giston -v
      
      Shows giston #{Giston::VERSION::STRING}

EOD

    def self.run(*argv)
      argv.flatten!
      argv << "help" if argv.empty?

      cmd = argv.slice!(0)

      case cmd
        when "help", "--help", "-h"
          msg help
        when "--version", "-v"
          msg "giston #{Giston::VERSION::STRING}"
        when "update", "add", "remove"
          Giston::Commands.send(cmd, *argv)
        else
          msg help
        end
    end

    def self.msg(str)
      puts str
    end

    def self.help
      HALP
    end

  end
end
