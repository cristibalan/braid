# Braid

[![Build Status](https://secure.travis-ci.org/realityforge/braid.png?branch=master)](http://travis-ci.org/realityforge/braid)

Braid is a simple tool to help track git vendor branches in a git repository.

The project homepage is [here](http://github.com/realityforge/braid/wikis/home).

## Braid on Vendoring

Vendoring allows you take the source code of an external library and ensure it is version
controlled along with the main project. This is in contrast to including a reference to a
packaged version of an external library that is available in a binary artifact repository
such as Maven Central, RubyGems or NPM.

Vendoring is useful when you need to patch or customize the external libraries or the
external library is expected to co-evolve with the main project. The developer can make
changes to the main project and patch the library in a single commit.

The problem arises when the external library makes changes that you want to integrate into
your local vendored version or the developer makes changes to the local version that they
want integrated into the external library.

A typical "implementation" of vendoring is to simply download or checkout the source for the
external library, remove the .git or .svn directories and commit it to the main source tree.
However this approach makes it very difficult to update the library. When you want to update
the library do you re-apply your local changes onto a new copy of the vendored library or do
you re-apply the changes from the external library to local version. In both cases this
involves manual generation and application of patch files to manually checked out source trees.

This is where braid comes into play. Braid makes it easy to vendor in remote git repositories
and use an automated mechanism for updating the external library and generating patches to upgrade
the external library.

## Requirements

 * git 1.6+
 * main >= 4.2.0
 * open4 >= 1.0.1 (unless using jruby)

## Installing using rubygems - official releases

    gem install realityforge-braid

## Installing from source

    git clone git://github.com/realityforge/braid.git
    cd braid
    bundle install
    rake install # possibly requiring sudo

## Quick usage - ruby project

Let's assume we're writing something like gitnub that needs grit in lib/grit. Initialize the repo (nothing braid related here):

    git init gritty
    cd gritty
    touch README
    git add README
    git commit -m "initial commit"

Now let's vendor grit:

    braid add git://github.com/mojombo/grit.git lib/grit

And you're done! Braid vendored grit into lib/grit. Feel free to inspect the changes with git log or git show.

If further down the line, you want to bring new changes from grit in your repository, just update the mirror:

    braid update lib/grit

## Quick usage - rails project

Let's assume you want to start a new rails app called shiny. Initialize the repo (nothing braid related here):

    git init shiny
    cd shiny
    touch README
    git add README
    git commit -m "initial commit"

Vendor rails (this might take a while because the rails repo is huge!):

    braid add git://github.com/rails/rails.git vendor/rails

Create your new rails app (nothing braid related here):

    ruby vendor/rails/railties/bin/rails .
    git add .
    git commit -m "rails ."

Add any plugins you might need:

    braid add git://github.com/thoughtbot/shoulda.git -p
    braid add git://github.com/thoughtbot/factory_girl.git -p
    braid add git://github.com/mbleigh/subdomain-fu.git -p

And you're done! Braid vendored rails and your plugins. Feel free to inspect the changes with git log or git show.

If further down the line, you want to bring new changes from rails in your repository, just update the mirror:

    braid update vendor/rails

Or, if you want all mirrors updated:

    braid update

## More usage

Use the built in help system to find out about all commands and options:

    braid help
    braid help add # or braid add --help

You may also want to read [Usage and examples](http://github.com/realityforge/braid/wikis/usage-and-examples).

## Troubleshooting

Check [Troubleshooting](http://github.com/realityforge/braid/wikis/troubleshooting) if you're having issues.

# Credit

This tool is a downstream evolution of a identically named tool initially developed by Cristi Balan (evilchelu)
and Norbert Crombach (norbert). All credit goes to the original for the initial code and idea. Further maintenance
and bugs are courtesy of Peter Donald.

## Contributors (alphabetically)

* Alan Harper
* Christoph Sturm
* Cristi Balan (Original Author)
* Dennis Muhlestein
* Ferdinand Svehla
* Michael Klishin
* Norbert Crombach (Original Author)
* Roman Heinrich
* Travis Tilley
* Tyler Rick
