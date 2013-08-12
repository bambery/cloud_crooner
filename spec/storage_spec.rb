require 'spec_helper'
require 'securerandom'

describe CloudCrooner::Storage do
  describe 'initialization' do
    before(:each) do
      CloudCrooner.configure do |config|
        config.bucket_name = SecureRandom.hex
        config.prefix = 'static'
      end
      stub_env_vars
      @storage = CloudCrooner::Storage.new
    end # before each
    
    it 'sets the bucket name' do
      expect(@storage.instance_variable_get(:@bucket_name)).to eq(CloudCrooner.bucket_name)
    end # it

    it 'sets the prefix' do
      expect(@storage.instance_variable_get(:@prefix)).to eq(CloudCrooner.prefix)
    end

    it 'sets the manifest' do
      expect(@storage.instance_variable_get(:@manifest)).to eq(CloudCrooner.manifest)
    end

    after(:each) do
      reload_crooner
    end # after each
  end # describe 

  describe 'connects to S3' do
    before(:each) do
      CloudCrooner.configure do |config|
        config.bucket_name = SecureRandom.hex
        config.prefix = 'static'
      end
      stub_env_vars
      @storage = CloudCrooner::Storage.new
      mock_fog(@storage)
    end # before each
 
    it 'creates a connection to the AWS account' do
      expect(@storage.connection.directories).to be_an_instance_of(Fog::Storage::AWS::Directories) 
    end # it

    it 'can see the empty bucket' do
      expect(@storage.bucket.versions.first).to be_nil
    end # it

    after(:each) do
      reload_crooner
    end # after each
  end # connects to S3 

  describe 'interacting with files' do
    it 'should gather the precompiled files to upload from the manifest' do
      within_construct do |c|
        mock_environment(c)
        CloudCrooner.manifest.compile('a.js', 'b.js')
        @storage = CloudCrooner::Storage.new
        mock_fog(@storage)

        expect(@storage.local_compiled_assets).to include(File.join('assets/', CloudCrooner.sprockets['a.js'].digest_path)) 
        expect(@storage.local_compiled_assets).to include(File.join('assets/', CloudCrooner.sprockets['b.js'].digest_path)) 
      end #construct
    end #it 

    after(:each) do
      reload_crooner
    end # after each
  end #describe

  describe 'interacting with remote files' do
    it 'should upload a file to an empty bucket' do
      within_construct do |c|

        mock_environment(c)
        CloudCrooner.manifest.compile('a.css')
        @storage = CloudCrooner::Storage.new
        mock_fog(@storage)

        expect(@storage.remote_assets).to eq([])

        @storage.upload_file(File.join( 'assets', CloudCrooner.sprockets['a.css'].digest_path))

        expect(@storage.remote_assets).to include(File.join('assets/', CloudCrooner.sprockets['a.css'].digest_path))
      end # construct
    end # it

    it 'should set assets to expire in one year' do
      within_construct do |c|
        mock_environment(c)
        CloudCrooner.manifest.compile('a.css')
        @storage = CloudCrooner::Storage.new
        mock_fog(@storage)

        expect(@storage.remote_assets).to eq([])

        filename = File.join( 'assets', CloudCrooner.sprockets['a.css'].digest_path)

        @storage.upload_file(filename)

        expect(@storage.bucket.files.get(filename).cache_control).to eq("public, max-age=31557600") 
      end # construct
    end # it

    it 'should set the proper mime type' do
      within_construct do |c|

        mock_environment(c) 
        CloudCrooner.manifest.compile('a.css')
        @storage = CloudCrooner::Storage.new
        mock_fog(@storage)

        expect(@storage.remote_assets).to eq([])

        filename = File.join( 'assets', CloudCrooner.sprockets['a.css'].digest_path)

        @storage.upload_file(filename)

        expect(@storage.bucket.files.get(filename).content_type).to eq('text/css') 
      end # construct
    end # it

    it 'should upload the gzip version of a file when available and gzip is smaller' do
       within_construct do |c|

          mock_environment(c) 
          CloudCrooner.manifest.compile('c.css')
          @storage = CloudCrooner::Storage.new
          mock_fog(@storage)

          expect(@storage.remote_assets).to eq([])

          filename = File.join( 'assets', CloudCrooner.sprockets['c.css'].digest_path)

          @storage.upload_file(filename)
          expect(@storage.remote_assets).to include(filename)
          expect(@storage.bucket.files.get(filename).content_encoding).to eq('gzip')
      end # construct
    end # it
      
    it 'should not upload both the uncompressed and gzip version of a file' do
      within_construct do |c|

        mock_environment(c) 
        CloudCrooner.manifest.compile('c.css')
        @storage = CloudCrooner::Storage.new
        mock_fog(@storage)

        expect(@storage.remote_assets).to eq([])

        @storage.upload_file(File.join( 'assets', CloudCrooner.sprockets['c.css'].digest_path))

        expect(@storage.remote_assets.count).to eq(1)
      end # construct
    end # it

    it 'should upload the uncompressed file when the gzip is not smaller' do
      within_construct do |c|

        mock_environment(c)
        CloudCrooner.manifest.compile('b.css')
        @storage = CloudCrooner::Storage.new
        mock_fog(@storage)

        expect(@storage.remote_assets).to eq([])

        filename = File.join( 'assets', CloudCrooner.sprockets['b.css'].digest_path)

        @storage.upload_file(filename)
        expect(File.exist?(File.join(c, "public", filename + ".gz"))).to be_true
        expect(@storage.remote_assets).to include(filename)
        expect(@storage.bucket.files.get(filename).content_encoding).to be_nil 
      end # construct
    end # it

    it 'uploads all files from the manifest' do
      within_construct do |c|

        mock_environment(c)
        @storage = CloudCrooner::Storage.new
        mock_fog(@storage)
        CloudCrooner.manifest.compile(Dir[uncompiled_assets_dir(c) + "/*"])
        CloudCrooner.manifest.files.count.should eq(7)
        @storage.upload_files
        expect(local_equals_remote?(@storage)).to be_true 
        
      end # construct
    end #it 

    it 'does not re-upload existing files' do
      # this could be tested better, maybe by checking log messages sent
      within_construct do |c|

        mock_environment(c)
        @storage = CloudCrooner::Storage.new
        mock_fog(@storage)

        CloudCrooner.manifest.compile(Dir[uncompiled_assets_dir(c) + "/*"])
        CloudCrooner.manifest.files.count.should eq(7)

        @storage.upload_file(File.join(@storage.instance_variable_get(:@prefix), CloudCrooner.sprockets['a.js'].digest_path))
        @storage.upload_files
        expect(local_equals_remote?(@storage)).to be_true 
      end # construct
    end # it

    it 'deletes remote files not in manifest' do
      within_construct do |c|

        mock_environment(c)
        @storage = CloudCrooner::Storage.new
        mock_fog(@storage)

        CloudCrooner.manifest.compile(Dir[uncompiled_assets_dir(c) + "/*"])
        CloudCrooner.manifest.files.count.should eq(7)

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

    after(:each) do
      reload_crooner
    end

  end # describe
end # describe
