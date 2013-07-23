require 'spec_helper'
require 'cloud_crooner/storage'

describe CloudCrooner::Storage do
  before(:each) do
    custom_env = Sprockets::Environment.new 

    @app = Class.new(Sinatra::Base) do
      set :sprockets, custom_env
      set :assets_prefix, '/assets'
    end

    register CloudCrooner
    
     ENV.stub(:[]).with('AWS_REGION').and_return('eu-west-1')
     ENV.stub(:has_key?).with('AWS_REGION').and_return(true)
     ENV.stub(:[]).with('AWS_ACCESS_KEY_ID').and_return('asdf123')
     ENV.stub(:has_key?).with('AWS_ACCESS_KEY_ID').and_return(true)
     ENV.stub(:[]).with('AWS_SECRET_ACCESS_KEY').and_return('secret')
     ENV.stub(:has_key?).with('AWS_SECRET_ACCESS_KEY').and_return(true)

  end # before each

  @storage = CloudCrooner::Storage.new(CloudCrooner.config)

  expect(@storage.config.region).to eq('eu-west-1')




end
