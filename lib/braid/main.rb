require 'braid'

require 'rubygems'
require 'main'

Home = File.expand_path(ENV['HOME'] || '~')

# mostly blantantly stolen from ara's punch script
# main kicks ass!
Main {
  description <<-TXT
    braid is a simple tool to help track git repositories inside a git repository.

    Run 'braid commandname help' for more details.

    All operations will be executed in the braid/track branch.
    You can then merge back or cherry-pick changes.
  TXT

  # The "main" library doesn't provide a way to do this??
  def check_no_extra_args!
    if @argv.length > 0
      die 'Extra argument(s) passed to command.'
    end
  end

  mode(:add) {
    description <<-TXT
      Add a new mirror to be tracked.

        * adds metadata about the mirror to .braids.json
        * adds the git remotes to .git/config
        * fetches and merges remote code into given directory

      Name defaults:

        * remote/path         # => path
        * remote/path/trunk   # => path
        * remote/path.git     # => path
    TXT

    examples <<-TXT
      . braid add http://remote/path.git local/dir
      . braid add http://remote/path local/dir
    TXT

    mixin :argument_url, :optional_local_path, :option_branch, :option_tag, :option_revision, :option_verbose, :option_path

    run {
      check_no_extra_args!
      Braid.verbose = verbose
      Braid::Command.run(:Add, url, {'path' => local_path, 'branch' => branch, 'tag' => tag, 'revision' => revision, 'remote_path' => path})
    }
  }

  mode(:update) {
    description <<-TXT
      Update a braid mirror.

        * get new changes from remote
        * always creates a merge commit
        * updates metadata in .braids.json when revisions are changed
        * removes the git remote by default, --keep can be used to suppress that

      Defaults to updating all unlocked mirrors if none is specified.
    TXT

    examples <<-TXT
      . braid update
      . braid update local/dir
    TXT

    mixin :optional_local_path, :option_head, :option_revision, :option_tag, :option_branch, :option_verbose, :option_keep_remote

    run {
      check_no_extra_args!
      options = {
        'branch' => branch,
        'tag' => tag,
        'revision' => revision,
        'head' => head,
        'keep' => keep
      }
      Braid.verbose = verbose
      Braid::Command.run(:Update, local_path, options)
    }
  }

  mode(:remove) {
    description <<-TXT
      Remove a mirror.

        * removes metadata from .braids.json
        * removes the local directory and commits the removal
        * removes the git remote by default, --keep can be used to suppress that
    TXT

    examples <<-TXT
      . braid remove local/dir
    TXT

    mixin :argument_local_path, :option_verbose, :option_keep_remote

    run {
      check_no_extra_args!
      options = {
        :keep => keep
      }
      Braid.verbose = verbose
      Braid::Command.run(:Remove, local_path, options)
    }
  }

  mode(:diff) {
    description <<-TXT
      Show diff of local changes to mirror.

      Additional arguments for "git diff" may be passed.  "--" should be used to
      ensure they are not parsed as Braid options.  File paths to limit the diff are
      relative to the downstream repository (for more convenient completion), even
      though file paths in the diff are relative to the mirror.
    TXT

    mixin :optional_local_path, :option_verbose, :option_keep_remote

    synopsis (Main::Usage.default_synopsis(self) + ' [-- git_diff_arg*]')

    run {
      if @argv.length > 0 && @argv[0] == '--'
        @argv.shift
      end
      options = {
        'keep' => keep,
        'git_diff_args' => @argv
      }
      Braid.verbose = verbose
      Braid::Command.run(:Diff, local_path, options)
    }
  }

  mode(:push) {
    description <<-TXT
      Push local mirror changes to remote.
    TXT

    mixin :argument_local_path, :option_branch, :option_verbose, :option_keep_remote

    run {
      check_no_extra_args!
      options = {
        'keep' => keep,
        'branch' => branch
      }
      Braid.verbose = verbose
      Braid::Command.run(:Push, local_path, options)
    }
  }

  mode(:setup) {
    description <<-TXT
      Set up git remotes.
    TXT

    mixin :optional_local_path, :option_verbose, :option_force

    run {
      check_no_extra_args!
      Braid.verbose = verbose
      Braid.force = force
      Braid::Command.run(:Setup, local_path)
    }
  }

  mode(:version) {
    description 'Show braid version.'

    run {
      check_no_extra_args!
      puts "braid #{Braid::VERSION}"
    }
  }

  mode(:status) {
    description 'Show the status of all tracked mirrors (and if updates are available).'

    mixin :optional_local_path, :option_verbose

    run {
      check_no_extra_args!
      Braid.verbose = verbose
      Braid::Command.run(:Status, local_path)
    }
  }

  mode('upgrade-config') {
    description <<-DESC
      Upgrade your project's Braid configuration to the latest configuration version.
      Other commands will notify you when you need to do this.  This may make older
      versions of Braid unable to read the configuration and may introduce breaking
      changes in how the configuration is handled by Braid.  An upgrade that
      introduces breaking changes will not be performed without the
      --allow-breaking-changes option.
    DESC

    mixin :option_verbose

    option('dry-run') {
      optional
      desc 'Explain the consequences of the upgrade without performing it.'
      attr :dry_run
    }

    option('allow-breaking-changes') {
      optional
      desc <<-DESC
        Perform the upgrade even if it involves breaking changes.
      DESC
      attr :allow_breaking_changes
    }

    run {
      check_no_extra_args!
      options = {
        'dry_run' => dry_run,
        'allow_breaking_changes' => allow_breaking_changes
      }
      Braid.verbose = verbose
      Braid::Command.run(:UpgradeConfig, options)
    }
  }

  mixin(:argument_local_path) {
    argument(:local_path) {
      attr
    }
  }

  mixin(:optional_local_path) {
    argument(:local_path) {
      optional
      attr
    }
  }

  mixin(:argument_url) {
    argument(:url) {
      attr
    }
  }

  mixin(:option_branch) {
    option(:branch, :b) {
      optional
      argument :required
      desc 'remote branch name to track'
      attr
    }
  }

  mixin(:option_tag) {
    option(:tag, :t) {
      optional
      argument :required
      desc 'remote tag name to track'
      attr
    }
  }

  mixin(:option_path) {
    option(:path, :p) {
      optional
      argument :required
      desc 'remote path'
      attr
    }
  }

  mixin(:option_revision) {
    option(:revision, :r) {
      optional
      argument :required
      desc 'revision to track'
      attr
    }
  }

  mixin(:option_head) {
    option(:head) {
      optional
      desc 'unused option'
      attr
    }
  }

  mixin(:option_verbose) {
    option(:verbose, :v) {
      optional
      desc 'log shell commands'
      attr
    }
  }

  mixin(:option_force) {
    option(:force, :f) {
      optional
      desc 'force'
      attr
    }
  }

  mixin(:option_keep_remote) {
    option(:keep) {
      optional
      desc 'do not remove the remote'
      attr
    }
  }

  run { help! }
}
