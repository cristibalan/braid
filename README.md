# Braid

Braid is a simple tool to help track git and svn vendor branches in a git repository.

The project homepage is [here](http://github.com/evilchelu/braid/wikis/home).

## Requirements

 * git 1.6+ (and git-svn if you want to mirror svn repositories)
 * main >= 4.2.0
 * open4 >= 1.0.1 (unless using jruby)

## Installing using rubygems - official releases

    gem install braid

## Installing from source

    git clone git://github.com/evilchelu/braid.git
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

You may also want to read [Usage and examples](http://github.com/evilchelu/braid/wikis/usage-and-examples).

## Troubleshooting

Check [Troubleshooting](http://github.com/evilchelu/braid/wikis/troubleshooting) if you're having issues.

## Contributing

We appreciate any patches, error reports and usage ideas you may have. Please submit a lighthouse ticket or start a thread on the mailing list.

Bugs and feature requests: [braid project on lighthouse](http://evilchelu.lighthouseapp.com/projects/10600-braid)

Discussions and community support: [braid-gem google group](http://groups.google.com/group/braid-gem)

## Authors

 * Cristi Balan (evilchelu)
 * Norbert Crombach (norbert)

## Contributors (alphabetically)

* Alan Harper
* Christoph Sturm
* Dennis Muhlestein
* Ferdinand Svehla
* Michael Klishin
* Roman Heinrich
* Travis Tilley
* Tyler Rick
