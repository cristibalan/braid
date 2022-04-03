# Braid developer's guide

This file collects some useful information for developers of Braid.

## Type checking

As of 2022-03-20, we are starting to use [Sorbet](https://sorbet.org/) for
static type checking and code navigation in compatible IDEs.  Only parts of the
code are annotated so far, but we are already seeing maintainability benefits
for those parts.

Regarding IDE support: Sorbet provides [an
extension](https://sorbet.org/docs/vscode) for Visual Studio Code.  If you use
VSCodium, the extension is not available in Open VSX as of this writing
(2022-03-20), but it's easy enough to build and install from
[source](https://github.com/sorbet/sorbet/tree/master/vscode_extension).  In
theory, it should be possible to use the Sorbet language server with another
IDE, but we haven't researched this.

Sorbet annotations take the form of references to functions and constants
defined by the `sorbet-runtime` gem.  In addition to being recognized by the
static checker, these annotations are evaluated at runtime to raise an error if
a value does not have the claimed type.  The runtime checks are helpful for
catching inconsistencies between the code and the annotations, so we enable them
for the test suite.  However, we currently don't want them during normal use of
Braid by end users because of the risk of an incorrect annotation breaking
previously working functionality that isn't covered by the test suite, as well
as potential performance and compatibility concerns.  So by default, Braid uses
a simple fake implementation of `sorbet-runtime` (in
`lib/braid/sorbet/fake_runtime.rb`) that performs no checks.  We may enable the
runtime checks by default in the future if the performance and compatibility
concerns are addressed and we become confident enough in the correctness of our
annotations that we think the benefit of catching problems sooner (before they
lead to unexpected behavior) outweighs the risk of breaking otherwise working
functionality.

The environment variable `BRAID_USE_SORBET_RUNTIME=1` tells Braid to use the
real `sorbet-runtime` with runtime type checks.  The test suite sets it by
default, and you can also set it when running Braid manually during development.
If you need to temporarily run the test suite without runtime type checks to
facilitate some kind of debugging, you can set `BRAID_USE_SORBET_RUNTIME=0`.
Note that since `sorbet-runtime` is declared only as a development dependency of
Braid, if for some reason you want to use `BRAID_USE_SORBET_RUNTIME=1` in a
context that doesn't recognize development dependencies, it's your
responsibility to ensure that the correct version of `sorbet-runtime` is on the
load path.

The Sorbet static analyzer (`sorbet-static`) is only available for certain
operating systems (as of this writing, Linux and macOS; see
https://sorbet.org/docs/faq#what-platforms-does-sorbet-support) and will fail to
install on other operating systems (Windows).  Braid's Gemfile guesses based on
your operating system whether it should try to install `sorbet-static`.  If it
guesses wrong, please accept our regrets and modify the Gemfile locally to do
the right thing for your system, and consider contributing a fix.  If
`sorbet-static` is not installed, you won't be able to use its static type
checking and code navigation functionality.  However, `sorbet-runtime` works the
same way on all operating systems (when Braid is configured to use it as
described above).
