= README

Giston is a simple tool to help track svn vendor branches in your git repository. It's loosely based on the idea of piston, but it's more simplistic and it does less.

= INSTALLING

git clone git://git.che.lu/giston.git
cd giston
sudo ruby setup.rb

= USAGE

Giston stores it's metadata in a file called ".giston" located in the currend directory where giston is run. You can use "giston add" and "giston remove" to change it or just manually edit it as it's just YAML.

Run giston update to fetch changes from the remote repositories once you have stuff in your ".giston".

= ISSUES

Giston barely works and you'll definitely encounter bugs. Help is appreciated :).

Known issues are stored in the TODO.txt file in the root of the giston checkout.

