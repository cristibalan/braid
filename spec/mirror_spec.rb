require File.dirname(__FILE__) + '/test_helper'

describe 'Braid::Mirror.new_from_options' do
  it 'should default mirror to last path part, ignoring trailing .git' do
    new_from_options('http://path.git')
    expect(@mirror.path).to eq('path')
  end

  it 'should strip trailing slash from specified path' do
    new_from_options('http://path.git', 'path' => 'vendor/tools/mytool/')
    expect(@mirror.path).to eq('vendor/tools/mytool')
  end

  it 'should define local_ref correctly when explicit branch specified' do
    new_from_options('http://mytool.git', 'branch' => 'mybranch')
    expect(@mirror.local_ref).to eq('mybranch/braid/mytool/mybranch')
  end

  it 'should define local_ref correctly when explicit tag specified' do
    new_from_options('http://mytool.git', 'tag' => 'v1')
    expect(@mirror.local_ref).to eq('tags/v1')
  end

  it 'should raise an exception if both tag and branch specified' do
    expect {
      new_from_options('http://mytool.git', 'tag' => 'v1', 'branch' => 'mybranch')
    }.to raise_error(Braid::Mirror::NoTagAndBranch)
  end

  it 'should define remote_ref correctly when explicit branch specified' do
    new_from_options('http://mytool.git', 'branch' => 'mybranch')
    expect(@mirror.remote_ref).to eq('+refs/heads/mybranch')
  end

  it 'should define remote_ref correctly when explicit tag specified' do
    new_from_options('http://mytool.git', 'tag' => 'v1')
    expect(@mirror.remote_ref).to eq('+refs/tags/v1')
  end

  it 'should define remote correctly when explicit branch specified' do
    new_from_options('http://mytool.git', 'branch' => 'mybranch')
    expect(@mirror.remote).to eq('mybranch/braid/mytool')
  end

  it 'should define remote correctly when explicit tag specified' do
    new_from_options('http://mytool.git', 'tag' => 'v1')
    expect(@mirror.remote).to eq('v1/braid/mytool')
  end

  it 'should strip first dot from remote path for dot files and folders' do
    new_from_options('http://path.git', 'branch' => 'master', 'path' => '.dotfolder/.dotfile.ext')
    expect(@mirror.path).to eq('.dotfolder/.dotfile.ext')
    expect(@mirror.remote).to eq('master/braid/_dotfolder/_dotfile.ext')
  end

end

describe 'Braid::Mirror#base_revision' do
  it 'should be inferred when no revision is set' do
    @mirror = build_mirror
    expect(@mirror.revision).to be_nil
    @mirror.expects(:inferred_revision).returns('b' * 40)
    expect(@mirror.base_revision).to eq('b' * 40)
  end

  it 'should be the parsed hash for git mirrors' do
    @mirror = build_mirror('revision' => 'a' * 7)
    git.expects(:rev_parse).with('a' * 7).returns('a' * 40)
    expect(@mirror.base_revision).to eq('a' * 40)
  end
end

describe 'Braid::Mirror#inferred_revision' do
  it 'should return the last commit before the most recent update' do
    @mirror = new_from_options('git://path')
    git.expects(:rev_list).times(2).returns(
      "#{'a' * 40}\n",
      "commit #{'b' * 40}\n#{'t' * 40}\n"
    )
    git.expects(:tree_hash).with(@mirror.path, 'a' * 40).returns('t' * 40)
    expect(@mirror.send(:inferred_revision)).to eq('b' * 40)
  end
end

describe 'Braid::Mirror#cached?' do
  before(:each) do
    @mirror = new_from_options('git://path')
  end

  it 'should be true when the remote path matches the cache path' do
    git.expects(:remote_url).with(@mirror.remote).returns(git_cache.path(@mirror.url))
    expect(@mirror).to be_cached
  end

  it 'should be false if the remote does not point to the cache' do
    git.expects(:remote_url).with(@mirror.remote).returns(@mirror.url)
    expect(@mirror).not_to be_cached
  end
end
