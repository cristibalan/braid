require File.dirname(__FILE__) + '/integration_helper'

describe 'Running braid diff with a mirror' do
  before do
    FileUtils.rm_rf(TMP_PATH)
    FileUtils.mkdir_p(TMP_PATH)
    @repository_dir = create_git_repo_from_fixture('shiny')
    @vendor_repository_dir = create_git_repo_from_fixture('skit1')
    in_dir(@vendor_repository_dir) do
      run_command('git tag v1')
    end
  end

  describe 'braided directly in' do
    before do
      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir}")
      end
    end

    describe 'with no changes' do
      it 'with the mirror specified should emit no output' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff skit1")
        end

        expect(diff).to eq('')
      end

      it 'without specifying a mirror should emit only banners' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff")
        end

        expect(diff).to eq("=======================================================\nBraid: Diffing skit1\n=======================================================\n")
      end
    end

    describe 'with changes' do
      before do
        FileUtils.cp_r(File.join(FIXTURE_PATH, 'skit1.1') + '/.', "#{@repository_dir}/skit1")
        in_dir(@repository_dir) do
          run_command('git add *')
          run_command('git commit -m "Some local changes"')
        end
      end

      EXPECTED_DIFF=<<PATCH
diff --git a/layouts/layout.liquid b/layouts/layout.liquid
index 9f75009..25a4b32 100644
--- a/layouts/layout.liquid
+++ b/layouts/layout.liquid
@@ -22,7 +22,7 @@
 <![endif]-->
 </head>
 
-<body class="fixed orange">
+<body class="fixed green">
 <script type="text/javascript">loadPreferences()</script>
 
 <div id="wrapper">
PATCH

      it 'with the mirror specified should emit diff' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff skit1")
        end

        expect(diff).to eq(EXPECTED_DIFF)
      end

      it 'without specifying a mirror should emit diff and banners' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff")
        end

        expect(diff).to eq(<<BANNER + EXPECTED_DIFF)
=======================================================
Braid: Diffing skit1
=======================================================
BANNER
      end

      it 'in a new clone of the downstream repository should fetch the base revision and emit diff' do
        diff = nil
        CLONE_NAME = 'shiny-clone'
        in_dir(TMP_PATH) do
          run_command("git clone --quiet #{@repository_dir} #{CLONE_NAME}")
        end
        clone_dir = File.join(TMP_PATH, CLONE_NAME)
        in_dir(clone_dir) do
          diff = run_command("#{BRAID_BIN} diff skit1")
        end

        expect(diff).to eq(EXPECTED_DIFF)
      end

      it 'after pruning the base revision from the repository should fetch it again and emit diff' do
        # Note: It is not the intent of this test case to require that Braid
        # leave objects from the mirror in the main repository after it exits.
        # A design change to stop doing that would legitimately require this
        # test case to be modified or dropped.
        diff = nil
        in_dir(@repository_dir) do
          status_out = run_command("#{BRAID_BIN} status skit1")
          base_revision = /^skit1 \(([0-9a-f]{40})\)/.match(status_out)[1]
          # Make sure the base revision is in the repository as a sanity check.
          run_command("git rev-parse --verify --quiet #{base_revision}^{commit}")
          run_command('git gc --quiet --prune=all')
          # Make sure it's gone now so we know we're actually testing Braid's fetch behavior.
          run_command_expect_failure("git rev-parse --verify --quiet #{base_revision}^{commit}")

          diff = run_command("#{BRAID_BIN} diff skit1")

          # The base revision should be present again.
          run_command("git rev-parse --verify --quiet #{base_revision}^{commit}")
        end

        expect(diff).to eq(EXPECTED_DIFF)
      end
    end

    describe 'with uncommitted changes (some staged)' do
      before do
        FileUtils.cp_r(File.join(FIXTURE_PATH, 'skit1.1') + '/.', "#{@repository_dir}/skit1")
        in_dir(@repository_dir) do
          run_command('git add *')
        end
        FileUtils.cp_r(File.join(FIXTURE_PATH, 'skit1.2') + '/.', "#{@repository_dir}/skit1")
        # Now "orange" -> "green" is staged, "Happy boxying!" is unstaged.
      end

      it 'with the mirror specified should show all uncommitted changes' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff skit1")
        end

        expect(diff).to eq(<<PATCH)
diff --git a/layouts/layout.liquid b/layouts/layout.liquid
index 9f75009..7037e21 100644
--- a/layouts/layout.liquid
+++ b/layouts/layout.liquid
@@ -22,7 +22,7 @@
 <![endif]-->
 </head>
 
-<body class="fixed orange">
+<body class="fixed green">
 <script type="text/javascript">loadPreferences()</script>
 
 <div id="wrapper">
@@ -81,6 +81,8 @@
 
 <p>Have boxes with smaller text with the class "minor". See the "Recent" boxy below.</p>
 
+<p>Happy boxying!</p>
+
 </div>
 
 <div id="search" class="boxy short">
PATCH
      end

      it 'without specifying a mirror should show all uncommitted changes with a banner' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff")
        end

        expect(diff).to eq(<<PATCH)
=======================================================
Braid: Diffing skit1
=======================================================
diff --git a/layouts/layout.liquid b/layouts/layout.liquid
index 9f75009..7037e21 100644
--- a/layouts/layout.liquid
+++ b/layouts/layout.liquid
@@ -22,7 +22,7 @@
 <![endif]-->
 </head>
 
-<body class="fixed orange">
+<body class="fixed green">
 <script type="text/javascript">loadPreferences()</script>
 
 <div id="wrapper">
@@ -81,6 +81,8 @@
 
 <p>Have boxes with smaller text with the class "minor". See the "Recent" boxy below.</p>
 
+<p>Happy boxying!</p>
+
 </div>
 
 <div id="search" class="boxy short">
PATCH
      end

      it 'with the mirror specified and --cached should show only the staged uncommitted changes' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff skit1 -- --cached")
        end

        expect(diff).to eq(<<PATCH)
diff --git a/layouts/layout.liquid b/layouts/layout.liquid
index 9f75009..25a4b32 100644
--- a/layouts/layout.liquid
+++ b/layouts/layout.liquid
@@ -22,7 +22,7 @@
 <![endif]-->
 </head>
 
-<body class="fixed orange">
+<body class="fixed green">
 <script type="text/javascript">loadPreferences()</script>
 
 <div id="wrapper">
PATCH
      end

      # A simple test of `braid diff` with more than one extra argument, which
      # previously caused a crash.
      it 'with the mirror specified and -R --cached should show only the staged uncommitted changes in reverse' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff skit1 -- -R --cached")
        end

        expect(diff).to eq(<<PATCH)
diff --git b/layouts/layout.liquid a/layouts/layout.liquid
index 25a4b32..9f75009 100644
--- b/layouts/layout.liquid
+++ a/layouts/layout.liquid
@@ -22,7 +22,7 @@
 <![endif]-->
 </head>
 
-<body class="fixed green">
+<body class="fixed orange">
 <script type="text/javascript">loadPreferences()</script>
 
 <div id="wrapper">
PATCH
      end

      it 'without specifying a mirror and with --cached should show only the staged uncommitted changes with a banner' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff -- --cached")
        end

        expect(diff).to eq(<<PATCH)
=======================================================
Braid: Diffing skit1
=======================================================
diff --git a/layouts/layout.liquid b/layouts/layout.liquid
index 9f75009..25a4b32 100644
--- a/layouts/layout.liquid
+++ b/layouts/layout.liquid
@@ -22,7 +22,7 @@
 <![endif]-->
 </head>
 
-<body class="fixed orange">
+<body class="fixed green">
 <script type="text/javascript">loadPreferences()</script>
 
 <div id="wrapper">
PATCH
      end
    end

    describe 'with changes to multiple files and a file path argument' do
      before do
        FileUtils.cp_r(File.join(FIXTURE_PATH, 'skit1.3') + '/.', "#{@repository_dir}/skit1")
        in_dir(@repository_dir) do
          run_command('git add *')
          run_command('git commit -m "Some local changes"')
        end
      end

      it 'should show only the diff in the specified file' do
        diff = nil
        in_dir(@repository_dir) do
          # Test that file paths are taken relative to the downstream repository
          # root, as documented, rather than the mirror.
          diff = run_command("#{BRAID_BIN} diff skit1 -- skit1/layouts/README.md")
        end

        expect(diff).to eq(<<PATCH)
diff --git a/layouts/README.md b/layouts/README.md
new file mode 100644
index 0000000..69dc7e6
--- /dev/null
+++ b/layouts/README.md
@@ -0,0 +1 @@
+I would write something here if I knew what this was...
PATCH
      end
    end
  end

  describe 'braided subdirectory into' do
    before do
      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir} --path layouts skit-layouts")
      end
    end

    describe 'with no changes' do
      it 'with the mirror specified should emit no output' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff skit-layouts")
        end

        expect(diff).to eq('')
      end

      it 'without specifying a mirror should emit only banners' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff")
        end

        expect(diff).to eq("=======================================================\nBraid: Diffing skit-layouts\n=======================================================\n")
      end
    end


    describe 'with changes' do
      before do
        FileUtils.cp_r(File.join(FIXTURE_PATH, 'skit1.1') + '/layouts/.', "#{@repository_dir}/skit-layouts")
        in_dir(@repository_dir) do
          run_command('git add *')
          run_command('git commit -m "Some local changes"')
        end
      end

      it 'with the mirror specified should emit diff' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff skit-layouts")
        end

        expect(diff).to eq(<<PATCH)
diff --git a/layout.liquid b/layout.liquid
index 9f75009..25a4b32 100644
--- a/layout.liquid
+++ b/layout.liquid
@@ -22,7 +22,7 @@
 <![endif]-->
 </head>
 
-<body class="fixed orange">
+<body class="fixed green">
 <script type="text/javascript">loadPreferences()</script>
 
 <div id="wrapper">
PATCH
      end

      it 'without specifying a mirror should emit diff and banners' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff")
        end

        expect(diff).to eq(<<PATCH)
=======================================================
Braid: Diffing skit-layouts
=======================================================
diff --git a/layout.liquid b/layout.liquid
index 9f75009..25a4b32 100644
--- a/layout.liquid
+++ b/layout.liquid
@@ -22,7 +22,7 @@
 <![endif]-->
 </head>
 
-<body class="fixed orange">
+<body class="fixed green">
 <script type="text/javascript">loadPreferences()</script>
 
 <div id="wrapper">
PATCH
      end
    end
  end

  describe 'braided from a single file' do
    before do
      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir} --path layouts/layout.liquid skit-layout.liquid")
      end
    end

    describe 'with no changes' do
      it 'with the mirror specified should emit no output' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff skit-layout.liquid")
        end

        expect(diff).to eq('')
      end

      it 'without specifying a mirror should emit only banners' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff")
        end

        expect(diff).to eq("=======================================================\nBraid: Diffing skit-layout.liquid\n=======================================================\n")
      end
    end


    describe 'with changes' do
      before do
        FileUtils.cp_r(File.join(FIXTURE_PATH, 'skit1.1') + '/layouts/layout.liquid', "#{@repository_dir}/skit-layout.liquid",
          preserve: true)
        in_dir(@repository_dir) do
          run_command('git add *')
          run_command('git commit -m "Some local changes"')
        end
      end

      it 'with the mirror specified should emit diff' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff skit-layout.liquid")
        end

        expect(diff).to eq(<<PATCH)
diff --git a/layout.liquid b/skit-layout.liquid
index 9f75009..25a4b32 100644
--- a/layout.liquid
+++ b/skit-layout.liquid
@@ -22,7 +22,7 @@
 <![endif]-->
 </head>
 
-<body class="fixed orange">
+<body class="fixed green">
 <script type="text/javascript">loadPreferences()</script>
 
 <div id="wrapper">
PATCH
      end

      it 'without specifying a mirror should emit diff and banners' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff")
        end

        expect(diff).to eq(<<PATCH)
=======================================================
Braid: Diffing skit-layout.liquid
=======================================================
diff --git a/layout.liquid b/skit-layout.liquid
index 9f75009..25a4b32 100644
--- a/layout.liquid
+++ b/skit-layout.liquid
@@ -22,7 +22,7 @@
 <![endif]-->
 </head>
 
-<body class="fixed orange">
+<body class="fixed green">
 <script type="text/javascript">loadPreferences()</script>
 
 <div id="wrapper">
PATCH
      end
    end

    describe 'with changes including a mode change' do
      before do
        in_dir(@repository_dir) do
          @filemode_enabled = filemode_enabled
        end
        FileUtils.cp_r(File.join(FIXTURE_PATH, 'skit1.1x') + '/layouts/layout.liquid', "#{@repository_dir}/skit-layout.liquid",
          preserve: true)
        in_dir(@repository_dir) do
          run_command('git add *')
          run_command('git commit -m "Some local changes"')
        end
      end

      it 'with the mirror specified should emit diff' do
        # Right way to do this?  See
        # https://github.com/cucumber/aruba/issues/301 .  It's unclear what
        # we'd have to do to get the information in time to use :unless.  If
        # we don't do that, a success seems less bad than a known
        # failure ("pending").
        next unless @filemode_enabled

        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff skit-layout.liquid")
        end

        expect(diff).to eq(<<PATCH)
diff --git a/layout.liquid b/skit-layout.liquid
old mode 100644
new mode 100755
index 9f75009..25a4b32
--- a/layout.liquid
+++ b/skit-layout.liquid
@@ -22,7 +22,7 @@
 <![endif]-->
 </head>
 
-<body class="fixed orange">
+<body class="fixed green">
 <script type="text/javascript">loadPreferences()</script>
 
 <div id="wrapper">
PATCH
      end

      it 'without specifying a mirror should emit diff and banners' do
        next unless @filemode_enabled

        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff")
        end

        expect(diff).to eq(<<PATCH)
=======================================================
Braid: Diffing skit-layout.liquid
=======================================================
diff --git a/layout.liquid b/skit-layout.liquid
old mode 100644
new mode 100755
index 9f75009..25a4b32
--- a/layout.liquid
+++ b/skit-layout.liquid
@@ -22,7 +22,7 @@
 <![endif]-->
 </head>
 
-<body class="fixed orange">
+<body class="fixed green">
 <script type="text/javascript">loadPreferences()</script>
 
 <div id="wrapper">
PATCH
      end
    end
  end

  describe 'braided as a tag directly in' do
    before do
      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir} --tag v1")
      end
    end

    describe 'with no changes' do
      it 'with the mirror specified should emit no output' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff skit1")
        end

        expect(diff).to eq('')
      end

      it 'without specifying a mirror should emit only banners' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff")
        end

        expect(diff).to eq("=======================================================\nBraid: Diffing skit1\n=======================================================\n")
      end
    end

    describe 'with changes' do
      before do
        FileUtils.cp_r(File.join(FIXTURE_PATH, 'skit1.1') + '/.', "#{@repository_dir}/skit1")
        in_dir(@repository_dir) do
          run_command('git add *')
          run_command('git commit -m "Some local changes"')
        end
      end

      it 'with the mirror specified should emit diff' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff skit1")
        end

        expect(diff).to eq(<<PATCH)
diff --git a/layouts/layout.liquid b/layouts/layout.liquid
index 9f75009..25a4b32 100644
--- a/layouts/layout.liquid
+++ b/layouts/layout.liquid
@@ -22,7 +22,7 @@
 <![endif]-->
 </head>
 
-<body class="fixed orange">
+<body class="fixed green">
 <script type="text/javascript">loadPreferences()</script>
 
 <div id="wrapper">
PATCH
      end
    end
  end
end
