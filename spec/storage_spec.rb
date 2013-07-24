require 'spec_helper'
require 'cloud_crooner/storage'

describe CloudCrooner::Storage do
  describe 'initialization' do
    before(:each) do

      stub_env_vars

      @app = Class.new(Sinatra::Base) do
        set :sprockets, sprockets_env 
        set :assets_prefix, '/assets'
        register CloudCrooner
      end

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
  end # end initialization 

  describe 'interacting with files' do
    it 'should gather the files to upload from the manifest', :meow => true do
      within_construct do |c|

        sample_assets(c)
        # need to specify manifest so construct will clean it up
        manifest_file = c.join 'assets/manifest.json'

        @app = Class.new(Sinatra::Base) do
          set :sprockets, sprockets_env 
          set :assets_prefix, '/assets'
          set :manifest, Sprockets::Manifest.new(sprockets_env, manifest_file) 
          register CloudCrooner
        end

        CloudCrooner.config.manifest.compile('a.js', 'b.js')

        @storage = CloudCrooner::Storage.new(CloudCrooner.config)

        expect(@storage.local_assets).to include(File.join('/assets/', sprockets_env['a.js'].digest_path)) 
        expect(@storage.local_assets).to include(File.join('/assets/', sprockets_env['b.js'].digest_path)) 
      end #construct

    end # test

  end #describe
end


