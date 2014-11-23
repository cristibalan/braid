# Braid

[![Build Status](https://secure.travis-ci.org/realityforge/braid.png?branch=master)](http://travis-ci.org/realityforge/braid)

Braid is a simple tool to help track git vendor branches in a git repository.

The project homepage is [here](http://realityforge.github.io/braid).

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

Braid creates a file `.braids` in the root of your repository that contains references to
external libraries or mirrors. There are two types of mirrors in braid: squashed and full.
Mirrors are *squashed by default*, which is what you'll generally want because they're faster
and don't pollute your history with commits from the mirrors.

Full mirrors are useful when you want to view imported history in your own project. You usually
want this if the mirror is also a repository you have access to, for example, when using shared
code across projects.

Please note that you *cannot change* between mirror types after the initial add. You'll have to
remove the mirror and add it again.

## Installing using rubygems - official releases

    gem install realityforge-braid

## Installing from source

    git clone git://github.com/realityforge/braid.git
    cd braid
    bundle install
    rake install # possibly requiring sudo

## Quick usage - ruby project

Let's assume we're writing the project `myproject` that needs grit in lib/grit. Initialize the repo (nothing braid related here):

    git init myproject
    cd myproject
    touch README
    git add README
    git commit -m "initial commit"

Now let's vendor grit:

    braid add git://github.com/mojombo/grit.git lib/grit

And you're done! Braid vendored grit into lib/grit. Feel free to inspect the changes with git log or git show.

If further down the line, you want to bring new changes from grit in your repository, just update the mirror:

    braid update lib/grit

Or, if you want all mirrors updated:

    braid update

## More usage

Use the built in help system to find out about all commands and options:

    braid help
    braid help add # or braid add --help

### Examples

#### Adding a mirror

    braid add git://github.com/rails/rails.git vendor/rails

#### Adding mirrors with revisions

    braid add --revision bf1b1e0 git://github.com/rails/rails.git vendor/rails

#### Adding mirrors with full history

    braid add --full git://github.com/mislav/will_paginate.git vendor/plugins/will_paginate

#### Updating mirrors

    # Update a specific mirror
    braid update vendor/plugins/cache_fu
    # Update all mirrors
    braid update

#### Updating mirrors with conflicts

If a braid update creates a conflict, braid will stop execution and leave the partially committed
files in your working copy, just like a normal git merge conflict would.

You will then have to resolve all conflicts and manually run `git commit`. The commit message is
already prepared.

If you want to cancel the braid update and the merge, you'll have to reset your working copy and
index with `git reset --hard`.

#### Locking and unlocking mirrors

    braid update --revision 6c1c16b vendor/rails
    braid update --head vendor/rails

#### Showing local changes made to mirrors

    braid diff vendor/rails

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
* Peter Donald (Current Maintainer)
* Roman Heinrich
* Travis Tilley
* Tyler Rick
