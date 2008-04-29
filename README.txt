= Braid

http://evil.che.lu/projects/braid/

== Description

Braid is a simple tool to help track git and svn vendor branches in a git
repository.

In purpose, it's similar to piston, but it's especially built on top of git
commands. This allows better integration with git and easier management of
merges.

Braid is "hosted on github":http://github.com/evilchelu/braid.

*NOTE:* You will need at least git 1.5.4.5+ to run braid. You'll also need the
open4 and main gems.

== Install with rubygems

  gem sources -a http://gems.github.com/  # only need to do this once
  gem install evilchelu-braid

== Install from the git repository

Get a clone of the git repository using:

  git clone git://github.com/evilchelu/braid.git
  cd braid
  rake install_gem
  braid --help # see usage

=== Usage

  braid help
  braid help COMMANDNAME

For more usage examples, documentation, feature requests and bug reporting,
check out the "braid wiki":http://github.com/evilchelu/braid/wikis.

=== Contributing

If you want to send a patch in, please fork the project on github, commit your
changes and send a pull request.

=== Mad props

Braid used to be quite lame before "Norbert Crombach":http://primetheory.org/
("github":http://github.com/norbert) resuscitated it by contribuing a bunch of
code.

He rocks! Go buy him a beer. 

