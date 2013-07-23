require 'spec_helper'
require 'cloud_crooner/storage'

describe CloudCrooner::Storage do
  before(:each) do
    custom_env = Sprockets::Environment.new 

    @app = Class.new(Sinatra::Base) do
      set :sprockets, custom_env
      set :assets_prefix, '/assets'
      register CloudCrooner
    end

    ENV.stub(:[]).and_return(nil)

    ENV.stub(:[]).with('AWS_REGION').and_return('eu-west-1')
    ENV.stub(:has_key?).with('AWS_REGION').and_return(true)
    ENV.stub(:[]).with('AWS_ACCESS_KEY_ID').and_return('asdf123')
    ENV.stub(:has_key?).with('AWS_ACCESS_KEY_ID').and_return(true)
    ENV.stub(:[]).with('AWS_SECRET_ACCESS_KEY').and_return('secret')
    ENV.stub(:has_key?).with('AWS_SECRET_ACCESS_KEY').and_return(true)

    CloudCrooner.config.bucket_name = "test-bucket"
    

    # mock out fog for testing
    Fog.mock!

    @storage = CloudCrooner::Storage.new(CloudCrooner.config)
  end # before each
  
  it 'initializes with the config' do
    expect(@storage.config.region).to eq('eu-west-1')
  end

  it 'creates a connection to the AWS account' do
    expect(@storage.connection.directories).to be_an_instance_of(Fog::Storage::AWS::Directories) 
  end

  it 'returns an empty list when grabbing an empty bucket' do
    expect(@storage.bucket).to be_nil 
  end

  it 'should gather the files to upload from the manifest' do
    expect(@storage.local_assets)
  end


end
