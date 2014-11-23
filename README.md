# Braid

[![Build Status](https://secure.travis-ci.org/realityforge/braid.png?branch=master)](http://travis-ci.org/realityforge/braid)

Braid is a simple tool to help track git vendor branches in a git repository.

The project homepage is [here](http://github.com/realityforge/braid/wikis/home).

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
* Dennis Muhlestein
* Ferdinand Svehla
* Michael Klishin
* Roman Heinrich
* Travis Tilley
* Tyler Rick
