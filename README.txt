= README

Braid is a simple tool for managing vendor branches across different SCMs.

http://evil.che.lu/projects/braid

= INSTALLING FORM RUBYGEMS

# gem not published yet. please install from git
sudo gem install braid

= INSTALLING FROM GIT

# install deps
sudo gem install main
sudo gem install open4

git clone git://github.com/evilchelu/braid.git
cd braid
rake install_gem

= USAGE

# create a git repo
git init moo
cd moo

# ideally you will also do these, but they are just good practices
git config --global mirror.summary true
git checkout -b localwork

# adding mirrors
braid add git://blah
braid add svn://muh
gitk braid/track
git merge braid/track

# updating mirrors
braid update muh
braid update
git merge braid/track

# removing mirrors
braid remove blah
braid remove muh
git merge braid/track

= MORE USAGE

Braid stores it's metadata in a file called ".braids" located in the current directory where braid is run.

For full usage docs run:

braid help
braid help COMMANDNAME

= POSSIBLE PROBLEMS

In a multiuser setup people won't have all the remote branches setup. But nothing is really lost, yet.

Theoretically if you add the same remotes on other checkout and set the branches correctly things could be made to just work(TM).

= ISSUES

Braid barely works and you'll definitely encounter bugs. Help is appreciated :).

For now, known issues and feature requests are stored in the TODO.txt file in the root of the braid checkout.

