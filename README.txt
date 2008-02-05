= README

Braid is a simple tool for managing vendor branches across different SCMs.

http://evil.che.lu/projects/braid.git

= INSTALLING FORM RUBYGEMS

# not working yet. please install from git
sudo gem install braid

= INSTALLING FROM GIT

# install deps
sudo gem install main

git clone git://github.com/evilchelu/braid.git
cd braid
rake install_gem

= USAGE

Braid stores it's metadata in a file called ".braids" located in the currend directory where braid is run. Run "braid" to see the full usage instructions.

= ISSUES

Braid barely works and you'll definitely encounter bugs. Help is appreciated :).

For now, known issues and feature requests are stored in the TODO.txt file in the root of the braid checkout.

