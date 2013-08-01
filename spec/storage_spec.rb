require 'spec_helper'
require 'cloud_crooner/storage'

def mock_fog(storage)
  stub_env_vars
  Fog.mock!
  storage.config.bucket_name = SecureRandom.hex
  storage.connection.directories.create(
    :key => storage.config.bucket_name,
    :public => true
  )
end

describe CloudCrooner::Storage do
  describe 'initialization' do
    before(:each) do

      Class.new(Sinatra::Base) do
        set :sprockets, sprockets_env 
        set :assets_prefix, '/assets'
        register CloudCrooner
      end

      @storage = CloudCrooner::Storage.new(CloudCrooner.config)
      mock_fog(@storage)
    end # before each
    
    it 'initializes with the config' do
      expect(@storage.config.region).to eq('eu-west-1')
    end

    it 'creates a connection to the AWS account' do
      expect(@storage.connection.directories).to be_an_instance_of(Fog::Storage::AWS::Directories) 
    end

    #    this tests nothing
#    it 'returns an empty list when grabbing an empty bucket' do
#      expect(@storage.bucket.versions.first).to be_nil
#    end
  end # end initialization 

  describe 'interacting with files' do
    it 'should gather the precompiled files to upload from the manifest' do
      within_construct do |c|
        mock_app(c)
        CloudCrooner.config.manifest.compile('a.js', 'b.js')
        @storage = CloudCrooner::Storage.new(CloudCrooner.config)
        mock_fog(@storage)

        expect(@storage.local_compiled_assets).to include(File.join('assets/', sprockets_env['a.js'].digest_path)) 
        expect(@storage.local_compiled_assets).to include(File.join('assets/', sprockets_env['b.js'].digest_path)) 
      end #construct

    end #it 

    it 'should upload a file to an empty bucket' do
      within_construct do |c|

        mock_app(c)
        CloudCrooner.config.manifest.compile('a.css')
        @storage = CloudCrooner::Storage.new(CloudCrooner.config)
        mock_fog(@storage)

        expect(@storage.remote_assets).to eq([])

        @storage.upload_file(File.join( 'assets', sprockets_env['a.css'].digest_path))

        expect(@storage.remote_assets).to include(File.join('assets/', sprockets_env['a.css'].digest_path))
      end # construct
    end # it

    it 'should set assets to expire in one year' do
      within_construct do |c|

        mock_app(c)
        CloudCrooner.config.manifest.compile('a.css')
        @storage = CloudCrooner::Storage.new(CloudCrooner.config)
        mock_fog(@storage)

        expect(@storage.remote_assets).to eq([])

        filename = File.join( 'assets', sprockets_env['a.css'].digest_path)

        @storage.upload_file(filename)

        expect(@storage.bucket.files.get(filename).cache_control).to eq("public, max-age=31557600") 
      end
    end

    it 'should make the assets public by default' do
      pending("currently no way to set custom headers")
    end

    it 'should set the proper mime type' do
      pending('one check should be enough')
    end

    it 'should upload the gzip version of a file when available and gzip is smaller' do
       within_construct do |c|

          mock_app(c)
          CloudCrooner.config.manifest.compile('c.css')
          @storage = CloudCrooner::Storage.new(CloudCrooner.config)
          mock_fog(@storage)

          expect(@storage.remote_assets).to eq([])

          filename = File.join( 'assets', sprockets_env['c.css'].digest_path)

          @storage.upload_file(filename)
          expect(@storage.remote_assets).to include(filename)
          expect(@storage.bucket.files.get(filename).content_encoding).to eq('gzip')
      end # construct
    end # it
      
    it 'should not upload both the uncompressed and gzip version of a file' do
      within_construct do |c|

        mock_app(c)
        CloudCrooner.config.manifest.compile('c.css')
        @storage = CloudCrooner::Storage.new(CloudCrooner.config)
        mock_fog(@storage)

        expect(@storage.remote_assets).to eq([])

        @storage.upload_file(File.join( 'assets', sprockets_env['c.css'].digest_path))

        expect(@storage.remote_assets.count).to eq(1)
      end
    end

    it 'should upload the uncompressed file when the gzip is not smaller' do
      within_construct do |c|

        mock_app(c)
        CloudCrooner.config.manifest.compile('b.css')
        @storage = CloudCrooner::Storage.new(CloudCrooner.config)
        mock_fog(@storage)

        expect(@storage.remote_assets).to eq([])

        filename = File.join( 'assets', sprockets_env['b.css'].digest_path)

        @storage.upload_file(filename)
        expect(File.exist?(File.join(c, "public", filename + ".gz"))).to be_true
        expect(@storage.remote_assets).to include(filename)
        expect(@storage.bucket.files.get(filename).content_encoding).to be_nil 
      end
    end

    it 'uploads all files from the manifest' do
      within_construct do |c|

        mock_app(c)
        @storage = CloudCrooner::Storage.new(CloudCrooner.config)
        mock_fog(@storage)
        CloudCrooner.config.manifest.compile(Dir[uncompiled_assets_dir(c) + "/*"])
        CloudCrooner.config.manifest.files.count.should eq(7)
        @storage.upload_files
        expect(@storage.local_equals_remote?).to be_true 
        
      end # construct
    end #it 

    it 'does not re-upload existing files' do
      # this could be tested better, maybe by checking log messages sent
      within_construct do |c|

        mock_app(c)
        @storage = CloudCrooner::Storage.new(CloudCrooner.config)
        mock_fog(@storage)

        CloudCrooner.config.manifest.compile(Dir[uncompiled_assets_dir(c) + "/*"])
        CloudCrooner.config.manifest.files.count.should eq(7)

        @storage.upload_file(File.join(@storage.config.prefix, sprockets_env['a.js'].digest_path))
        @storage.upload_files
        expect(@storage.local_equals_remote?).to be_true 
      end # construct
    end # it

    it 'deletes remote files not in manifest' do
      within_construct do |c|

        mock_app(c)
        @storage = CloudCrooner::Storage.new(CloudCrooner.config)
        mock_fog(@storage)

        CloudCrooner.config.manifest.compile(Dir[uncompiled_assets_dir(c) + "/*"])
        CloudCrooner.config.manifest.files.count.should eq(7)

        # upload a non-manifest tracked file
        @storage.bucket.files.create(
          :key => 'assets/fake-file.html',
          :body => 'meowmeow',
          :public => true
        )
        
        expect(@storage.remote_assets).to include('assets/fake-file.html')
        @storage.clean_remote 
        expect(@storage.remote_assets).to_not include('assets/fake-file.html')

      end #construct
    end # it

  end # describe
end
