# Braid

[![Build Status](https://secure.travis-ci.org/cristibalan/braid.svg?branch=master)](http://travis-ci.org/cristibalan/braid)
[![Gem](https://img.shields.io/gem/v/braid.svg?maxAge=2592000)](https://rubygems.org/gems/braid)

Braid is a simple tool to help track vendor branches in a
[Git](http://git-scm.com/) repository.

## Motivation

Vendoring allows you take the source code of an external library and ensure it's
version controlled along with the main project. This is in contrast to including
a reference to a packaged version of an external library that is available in a
binary artifact repository such as Maven Central, RubyGems or NPM.

Vendoring is useful when you need to patch or customize the external libraries
or the external library is expected to co-evolve with the main project. The
developer can make changes to the main project and patch the library in a single
commit.

The problem arises when the external library makes changes that you want to
integrate into your local vendored version or the developer makes changes to the
local version that they want integrated into the external library.

A typical "implementation" of vendoring is to simply download or checkout the
source for the external library, remove the `.git` or `.svn` directories and
commit it to the main source tree. However this approach makes it very difficult
to update the library. When you want to update the library do you re-apply your
local changes onto a new copy of the vendored library or do you re-apply the
changes from the external library to local version? Both cases involve manual
generation and application of patch files to source trees.

This is where Braid comes into play. Braid makes it easy to vendor in remote git
repositories and use an automated mechanism for updating the external library
and generating patches to upgrade the external library.

Braid creates a file `.braids.json` in the root of your repository that contains
references to external libraries or mirrors. The configuration allows you to control
aspects of the mirroring process such as;

* whether the mirror is locked to a particular version of the external library.
* whether the mirror is tracking a tag or a branch.
* whether the mirror includes the entire external library or just a subdirectory.

## Installation

    gem install braid

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

If further down the line, you want to bring new changes from grit into your repository, just update the mirror:

    braid update lib/grit

If you make changes to the grit library and want to generate a patch file so that you can submit the patch file
to the grit project:

    braid diff lib/grit > grit.patch

Alternatively you can push changes back to the source directory directly using the following command. The command
will push the changes to the branch `myproject_customizations` that has been branched off the source branch (`master`
in this example). Omit the `--branch` argument to push directly to the source branch.

    braid push lib/grit --branch myproject_customizations

Once those changes have been applied to grit you probably want to update your local version of grit again.

    braid update lib/grit

## More usage

Use the built in help system to find out about all commands and options:

    braid help
    braid help add # or braid add --help

### Examples

#### Adding a mirror

    braid add git://github.com/rails/rails.git vendor/rails

#### Adding a subdirectory from a mirror

This is useful if you want to add a subdirectory from a mirror into your own project.

    braid add --path dist https://github.com/twbs/bootstrap.git vendor/assets/bootstrap

#### Adding a mirror based on a branch

    braid add --branch 5-0-stable https://github.com/rails/rails.git vendor/rails

#### Adding a mirror based on a tag

    braid add --tag v1.0 https://github.com/realityforge/backpack.git vendor/tools/backpack

#### Adding mirror locked to a revision

    braid add --revision bf1b1e0 git://github.com/rails/rails.git vendor/rails

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

Lock to a particular version in the mirror.

    braid update --revision 6c1c16b vendor/rails

Go back to tracking a particular branch.

    braid update --branch master vendor/rails

#### Showing local changes made to mirrors

    braid diff vendor/rails

## Supported environments

As of this writing (2022-01-20), we try to keep Braid working at least on Linux
and Windows with recent versions of its dependencies (Git, Ruby, gems, etc.).
Your mileage on other operating systems or with other versions of dependencies
may vary.  We don't have a procedure in place to systematically test Braid in
multiple environments; typically, Braid developers just run the test suite on
their own systems with whatever is installed.  So breakages may sometimes occur.
If you run into an environment-related problem, please report it and we'll fix
it if feasible.  Contributions to improve testing of Braid would be welcome.

## Braid version compatibility

Since Braid has been regularly changing the configuration format and adding new
features that some projects may choose to rely on, and somewhat less often
making breaking changes in how the configuration is handled, problems can arise
if different developers work on the same project using different versions of
Braid.  Since version 1.1.0, Braid refuses to operate if it detects potentially
problematic version skew.  If this happens, Braid will tell you what you can do.
If you'd like an overview of what to expect, read on.

Roughly speaking, the `.braids.json` configuration file contains a configuration
version number that corresponds to a range of compatible Braid minor versions
(`x.y`). "Patch" upgrades to Braid (i.e., `x.y.z` -> `x.y.(z+1)`) will never
(intentionally!) have configuration compatibility implications and are always
recommended as they may fix critical bugs.

If you use a Braid version too old for your configuration file, Braid will
direct you to the [configuration version history page](config_versions.md) with
instructions to upgrade Braid.  If you use a Braid version too new, Braid will
tell you how you can upgrade your configuration file or find a compatible older
Braid version to use.  (As an exception, a newer version of Braid can run
read-only commands on an older configuration file without upgrading it if there
are no breaking changes.)  If you upgrade your configuration file, then other
developers on the project may need to upgrade Braid.  Braid does not support
downgrading a configuration file, though you can revert the commit that upgraded
it if you haven't made any subsequent changes to the configuration.

If you work on multiple projects, you may need to install multiple versions of
Braid and manually run the correct version for each project.  Fortunately, the
RubyGems system makes this reasonably straightforward.

Another approach is to standardize the Braid version for a project by listing
Braid in a `Gemfile` (either checking in `Gemfile.lock` or using a version
constraint in the `Gemfile`) and run the project's version of Braid via
[Bundler](http://bundler.io/) with `bundle exec braid`.  Even non-Ruby projects
can do this if it's acceptable to have a `Gemfile` and `Gemfile.lock`.  Ruby
projects that don't want Braid to interact with their other gems can potentially
put the `Gemfile` in a subdirectory and provide a wrapper script for `bundle`
that sets the `BUNDLE_GEMFILE` environment variable.  We do not yet have enough
experience with this approach to make a firm recommendation for or against it.

This is the best design we could find to prevent surprises and adequately
support normal development processes while minimizing the additional maintenance
cost of the version compatibility mechanism.  We want to have a scheme in place
that is robust enough to make it reasonable to encourage serious adoption of
Braid, yet we don't want to spend extra work adding conveniences until there's
evidence of sufficient demand for them.

## Contributing

We appreciate any patches, error reports and usage ideas you may have. Please
submit an issue or pull request on GitHub.

### Subversion

While preparing to release Braid v1.0 the support for subversion repositories was removed as
there was no active maintainers and inadequate test coverage. If there is anyone motivated to
re-add and maintain the Subversion support, please contact the authors.

# Authors

* Cristi Balan
* Norbert Crombach
* Peter Donald

## Contributors (alphabetically)

* Alan Harper
* Brad Durrow
* Christoph Sturm
* Dennis Muhlestein
* Ferdinand Svehla
* Matt McCutchen
* Michael Klishin
* Roman Heinrich
* Travis Tilley
* Tyler Rick
