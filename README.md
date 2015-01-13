# Braid

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

Braid creates a file `.braids` in the root of your repository that contains
references to external libraries or mirrors. There are two types of mirrors in
Braid: squashed and full. Mirrors are squashed by default, which is what you'll
generally want because they're faster and don't pollute your history with
commits from the mirrors.

Full mirrors are useful when you want to view imported history in your own
project. You usually want this if the mirror is also a repository you have
access to, for example, when using shared code across projects.

Please note that you cannot change between mirror types after the initial add.
You'll have to remove the mirror and add it again.

## Installation

    gem install braid

## Examples and usage

Let's assume you're working on a project that needs
[Grit](https://https://github.com/mojombo/grit) in `lib/grit`.

Now let's vendor Grit:

    $ braid add https://github.com/mojombo/grit.git lib/grit

Done. Feel free to inspect the changes with `git log` or `git show`.

If, further down the line, you want to bring new changes from Grit into your
parent repository:

    $ braid update lib/grit

If you make changes to the vendored library and want to generate a patch file
that you can submit back to the project:

    $ braid diff lib/grit > grit.patch

Use the built-in help system to find out about all commands and options:

    $ braid help
    $ braid help add

### Updating mirrors with conflicts

If a `braid update` creates a conflict, Braid will stop execution and leave the
partially committed files in your working copy, just like a normal `git merge`
conflict would.

You'll have to resolve all conflicts and manually run `git commit`. The commit
message is already prepared.

If you want to cancel the update and the merge, you have to reset your working
copy and index with `git reset --hard`.

## Contributing

We appreciate any patches, error reports and usage ideas you may have. Please
submit an issue or pull request on GitHub.

# Authors

* Cristi Balan
* Norbert Crombach
* Peter Donald
