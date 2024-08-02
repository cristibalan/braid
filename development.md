# Braid developer's guide

This file collects some useful information for developers of Braid.

## Type checking

As of 2022-03-20, we are starting to use [Sorbet](https://sorbet.org/) for
static type checking and code navigation in compatible IDEs.  Only parts of the
code are annotated so far, but we are already seeing maintainability benefits
for those parts.

**Regarding IDE support:** Sorbet provides [an
extension](https://sorbet.org/docs/vscode) for Visual Studio Code.  The
extension is also available in Open VSX for VSCodium users.  In
theory, it should be possible to use the Sorbet language server with another
IDE, but we haven't researched this.

Sorbet annotations take the form of references to functions and constants
defined by the `sorbet-runtime` gem.  In addition to being recognized by the
static checker, these annotations are executed at runtime and run code in
`sorbet-runtime` that checks that each value has the claimed type and raises an
error if not.  The runtime checks are helpful for
catching inconsistencies between the code and the annotations, so we enable them
by default for the test suite.
However, we currently don't want them during normal use of
Braid by end users because of the risk of an incorrect annotation breaking
previously working functionality that isn't covered by the test suite, as well
as potential performance and compatibility concerns.  So by default, Braid uses
a "fake" Sorbet runtime (in `lib/braid/sorbet/fake_runtime.rb`) that implements
only the `sorbet-runtime` APIs that Braid uses in a simple way with no runtime
type checks.  We may switch to
the real Sorbet runtime in the future if the performance and compatibility
concerns are addressed and we become confident enough in the correctness of our
annotations that we think the benefit of catching problems sooner (before they
lead to unexpected behavior) outweighs the risk of breaking otherwise working
functionality.  Since Braid only loads `sorbet-runtime` during development,
it is declared as a development dependency rather than a normal dependency.

The environment variable `BRAID_USE_SORBET_RUNTIME=1` tells Braid to use the
real Sorbet runtime with runtime type checks.  The test suite sets it by
default, which is typically what you want during development to catch incorrect
annotations.  However, as part of the final validation of a change, it's
important to run the test suite with `BRAID_USE_SORBET_RUNTIME=0` to detect if
Braid has been changed to use an additional API of the real Sorbet runtime that
isn't yet implemented in the fake one, since that would otherwise cause Braid to
fail during use by end users.  You can also run the test suite with
`BRAID_USE_SORBET_RUNTIME=0` during development to temporarily bypass the
runtime type checks if they are getting in the way of other testing you want to
do.

When you run Braid directly rather than via the test suite, the default is
`BRAID_USE_SORBET_RUNTIME=0` as it is for end users.  You can set
`BRAID_USE_SORBET_RUNTIME=1` to use the real Sorbet runtime and get the runtime
type checks, assuming you're running Braid from a development tree via the
standard Bundler setup or via another mechanism that honors the development
dependency on `sorbet-runtime`.  If you run Braid with
`BRAID_USE_SORBET_RUNTIME=1` via a mechanism that does not honor development
dependencies (e.g., from a released gem), it's your responsibility to ensure
that the correct version of `sorbet-runtime` is on the load path, otherwise
Braid will most likely fail.

The Sorbet static analyzer (`sorbet-static`) is only available for [certain
operating
systems](https://sorbet.org/docs/faq#what-platforms-does-sorbet-support) (as of
this writing, Linux and macOS) and will fail to install on other operating
systems (Windows).  Braid's Gemfile guesses based on your operating system
whether it should try to install `sorbet-static`.  If it guesses wrong, please
accept our regrets and modify the Gemfile locally to do the right thing for your
system, and consider contributing a fix.  If `sorbet-static` is not installed,
you won't be able to use its static type checking and code navigation
functionality.  However, `sorbet-runtime` works the same way on all operating
systems (when Braid is configured to use it as described above).

## Matt's checklist for validating a change to Braid

This is not an official policy at this point, but I thought I would go ahead and
make it public in case anyone else wants to use it.

TODO: Running all these steps is a big hassle.  Automate it better?

- `bundle exec rake` in my regular development environment on Linux: runs the
  test suite with the real Sorbet runtime, plus type checking and packaging.

- `BRAID_USE_SORBET_RUNTIME=0 bundle exec rake spec` to catch missing
  functionality in the fake Sorbet runtime.

- `bundle exec rake spec` with the oldest version of Git that Braid claims to
  support (`REQUIRED_GIT_VERSION`) added to `$PATH`.

- `bundle exec rake spec` with Git built from the upstream `next` branch added
  to `$PATH`.  This helps catch upcoming incompatibilities a little sooner.

- `bundle exec rake spec` in my Windows VM.

- Ask Peter to test on macOS as desired.
