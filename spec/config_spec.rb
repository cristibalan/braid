require File.dirname(__FILE__) + '/test_helper'

describe 'Braid::Config, when empty' do
  before(:each) do
    @config = Braid::Config.new({'config_file' => 'tmp.yml'})
  end

  after(:each) do
    FileUtils.rm('tmp.yml') rescue nil
  end

  it 'should not get a mirror by name' do
    expect(@config.get('path')).to be_nil
    expect { @config.get!('path') }.to raise_error(Braid::Config::MirrorDoesNotExist)
  end

  it 'should add a mirror and its params' do
    @mirror = build_mirror
    @config.add(@mirror)
    expect(@config.get('path').path).not_to be_nil
  end
end

describe 'Braid::Config, with one mirror' do
  before(:each) do
    @config = Braid::Config.new({'config_file' => 'tmp.yml'})
    @mirror = build_mirror
    @config.add(@mirror)
  end

  after(:each) do
    FileUtils.rm('tmp.yml') rescue nil
  end

  it 'should get the mirror by name' do
    expect(@config.get('path')).to eq(@mirror)
    expect(@config.get!('path')).to eq(@mirror)
  end

  it 'should raise when trying to overwrite a mirror on add' do
    expect { @config.add(@mirror) }.to raise_error(Braid::Config::PathAlreadyInUse)
  end

  it 'should remove the mirror' do
    @config.remove(@mirror)
    expect(@config.get('path')).to be_nil
  end

  it 'should update the mirror with new params' do
    @mirror.branch = 'other'
    @config.update(@mirror)
    expect(@config.get('path').attributes).to eq({'branch' => 'other'})
  end

  it 'should raise when trying to update nonexistent mirror' do
    @mirror.instance_variable_set('@path', 'other')
    expect { @config.update(@mirror) }.to raise_error(Braid::Config::MirrorDoesNotExist)
  end
end
