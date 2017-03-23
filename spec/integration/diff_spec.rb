require File.dirname(__FILE__) + '/integration_helper'

describe 'Running braid diff on a mirror' do
  before do
    FileUtils.rm_rf(TMP_PATH)
    FileUtils.mkdir_p(TMP_PATH)
    @repository_dir = create_git_repo_from_fixture('shiny')
    @vendor_repository_dir = create_git_repo_from_fixture('skit1')
  end

  describe 'braided directly in' do
    before do
      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir}")
      end
    end

    describe 'with no changes' do
      it 'should emit no output when named in braid diff' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff skit1")
        end

        expect(diff).to eq('')
      end

      it 'should emit only banners when braid diff all' do
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

      it 'should emit diff when named in braid diff' do
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

      it 'should emit only banners when braid diff all' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff")
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
  end

  describe 'braided subdirectory into' do
    before do
      in_dir(@repository_dir) do
        run_command("#{BRAID_BIN} add #{@vendor_repository_dir} --path layouts")
      end
    end

    describe 'with no changes' do
      it 'should emit no output when named in braid diff' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff skit1")
        end

        expect(diff).to eq('')
      end

      it 'should emit only banners when braid diff all' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff")
        end

        expect(diff).to eq("=======================================================\nBraid: Diffing skit1\n=======================================================\n")
      end
    end


    describe 'with changes' do
      before do
        FileUtils.cp_r(File.join(FIXTURE_PATH, 'skit1.1') + '/layouts/.', "#{@repository_dir}/skit1")
        in_dir(@repository_dir) do
          run_command('git add *')
          run_command('git commit -m "Some local changes"')
        end
      end

      it 'should emit diff when named in braid diff' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff skit1")
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

      it 'should emit only banners when braid diff all' do
        diff = nil
        in_dir(@repository_dir) do
          diff = run_command("#{BRAID_BIN} diff")
        end

        expect(diff).to eq(<<PATCH)
=======================================================
Braid: Diffing skit1
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
end
