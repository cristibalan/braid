require File.dirname(__FILE__) + '/test_helper'

describe 'Braid::Operations::Git#remote_url' do
  it 'should use git config' do
    # FIXME weak test
    git.stubs(:invoke).with(:config, 'remote.braid/git/one.url').returns('git://path')
    expect(git.remote_url('braid/git/one')).to eq('git://path')
  end
end

describe 'Braid::Operations::Git#rev_parse' do
  it 'should return the full hash when a hash is found' do
    full_revision = 'a' * 40
    git.expects(:exec).returns([0, full_revision, ''])
    expect(git.rev_parse('a' * 7)).to eq(full_revision)
  end

  it 'should raise a revision error when the hash is not found' do
    ambiguous_revision = 'b' * 7
    git.expects(:exec).returns([1, ambiguous_revision, 'fatal: ...'])
    expect { git.rev_parse(ambiguous_revision) }.to raise_error(Braid::Operations::UnknownRevision)
  end
end

describe 'Braid::Operations::Git#version' do
  ACTUAL_VERSION = '1.5.5.1.98.gf0ec4'

  before(:each) do
    git.expects(:exec).returns([0, "git version #{ACTUAL_VERSION}\n", ''])
  end

  it 'should extract from git --version output' do
    expect(git.version).to eq(ACTUAL_VERSION)
  end
end

describe 'Braid::Operations::Git#require_version' do
  REQUIRED_VERSION = '1.5.4.5'
  PASS_VERSIONS    = %w(1.5.4.6 1.5.5 1.6 1.5.4.5.2 1.5.5.1.98.gf0ec4)
  FAIL_VERSIONS    = %w(1.5.4.4 1.5.4 1.5.3 1.4.5.6)

  def set_version(str)
    git.expects(:exec).returns([0, "git version #{str}\n", ''])
  end

  it 'should return true for higher revisions' do
    PASS_VERSIONS.each do |version|
      set_version(version)
      expect(git.require_version(REQUIRED_VERSION)).to eq(true)
    end
  end

  it 'should return false for lower revisions' do
    FAIL_VERSIONS.each do |version|
      set_version(version)
      expect(git.require_version(REQUIRED_VERSION)).to eq(false)
    end
  end
end

describe 'Braid::Operations::GitCache#path' do
  it 'should use the local cache directory and strip characters' do
    expect(git_cache.path('git://path')).to eq(File.join(Braid.local_cache_dir, 'git___path'))
    expect(git_cache.path('git@domain:repository.git')).to eq(File.join(Braid.local_cache_dir, 'git_domain_repository.git'))
  end
end
