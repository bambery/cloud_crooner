require 'spec_helper'

describe CloudCrooner do
  describe 'default general configuration' do

    it 'creates a sprockets environment' do 
      expect(CloudCrooner.sprockets).to be_an_instance_of(Sprockets::Environment)
    end

    it 'sets a default prefix' do
      expect(CloudCrooner.prefix).to eq("assets")
    end

    it 'sets a default public folder in dev' do
      expect(CloudCrooner.public_folder).to eq("public")
    end

    it 'defaults to remote enabled' do
      expect(CloudCrooner.remote_enabled?).to be_true
    end

    it "defaults to looking for assets in '/assets'" do
      expect(CloudCrooner.asset_paths).to eq(%w(assets))
    end

    it 'checks ENV for Amazon credentials' do
      ENV.stub(:[]).with("AWS_ACCESS_KEY_ID").and_return("asdf123")
      ENV.stub(:[]).with("AWS_SECRET_ACCESS_KEY").and_return("secret")
      ENV.stub(:has_key?).with("AWS_ACCESS_KEY_ID").and_return(true)
      ENV.stub(:has_key?).with("AWS_SECRET_ACCESS_KEY").and_return(true)

      expect(CloudCrooner.aws_access_key_id).to eq("asdf123")
      expect(CloudCrooner.aws_secret_access_key).to eq("secret")
    end # it

    it "checks ENV for bucket name" do
      ENV.stub(:[]).with("AWS_BUCKET_NAME").and_return("test-bucket")
      ENV.stub(:has_key?).with("AWS_BUCKET_NAME").and_return(true)

      expect(CloudCrooner.bucket_name).to eq("test-bucket")
    end #it

    it "checks ENV for region" do
      ENV.stub(:[]).with("AWS_REGION").and_return("eu-west-1")
      ENV.stub(:has_key?).with("AWS_REGION").and_return(true)

      expect(CloudCrooner.region).to eq("eu-west-1")
    end

    it "errors if the ENV region is not valid" do
      ENV.stub(:[]).with("AWS_REGION").and_return("shangrila")
      ENV.stub(:has_key?).with("AWS_REGION").and_return(true)

      expect{CloudCrooner.region}.to raise_error(CloudCrooner::FogSettingError)
    end

    it 'defaults to keeping 2 backups' do
      expect(CloudCrooner.backups_to_keep).to eq(2)
    end

  end # describe

  describe 'errors if missing required settings' do
    it "errors if region is not assigned" do
      ENV.stub(:[]).and_return(nil)
      ENV.stub(:has_key?).with("AWS_REGION").and_return(false)
      expect{CloudCrooner.region}.to raise_error(CloudCrooner::FogSettingError, "AWS Region must be set in ENV or in configure block")
    end

    it "errors if the bucket is not set" do
      ENV.stub(:[]).and_return(nil)
      ENV.stub(:has_key?).with("AWS_BUCKET_NAME").and_return(false)
      expect{CloudCrooner.bucket_name}.to raise_error(CloudCrooner::FogSettingError, "Bucket name must be set in ENV or configure block")
    end

    it "errors if aws access key id is unset" do
      ENV.stub(:[]).and_return(nil)
      ENV.stub(:has_key?).with("AWS_ACCESS_KEY_ID").and_return(false)
      expect{CloudCrooner.aws_access_key_id}.to raise_error
    end
    
    it "errors if aws secret access key is unset" do
      ENV.stub(:[]).and_return(nil)
      ENV.stub(:has_key?).with("AWS_SECRET_ACCESS_KEY").and_return(false)
      expect{CloudCrooner.aws_secret_access_key}.to raise_error
    end

  end

  describe 'default configuration that touches filesystem' do
    # aka: these tests require temp files and constructs 

    it 'creates a manifest' do
      within_construct do |c|
        c.directory 'public/assets'

        expect(CloudCrooner.manifest).to be_an_instance_of(Sprockets::Manifest)
        expect(CloudCrooner.manifest.dir).to eq(File.join(c, "public/assets"))
      end #construct
    end # it

    it 'defaults assets to compile to files under prefix' do
      within_construct do |c|
        asset_folder = c.directory 'assets'
        c.file('assets/a.css')
        c.file('assets/b.css')

        expect(CloudCrooner.assets_to_compile).to eq(%w(a.css b.css))
      end # construct
    end # it

    it 'adds the default asset path to sprockets load path' do
       within_construct do |c|
        asset_folder = c.directory 'assets'
        c.file('assets/a.css')

        expect(CloudCrooner.sprockets['a.css']).to be_an_instance_of(Sprockets::BundledAsset) 
        expect(CloudCrooner.sprockets['a.css'].pathname.to_s).to eq(File.join(c, 'assets', 'a.css'))

       end # construct 
    end # it

    it 'initializes sprockets-helpers in development' do
      within_construct do |c|
        c.file 'assets/a.css'
        CloudCrooner.configure_sprockets_helpers
        
        expect(Sprockets::Helpers.prefix).to eq('/assets')
        expect(context.stylesheet_tag('a.css')).to eq(%Q(<link rel="stylesheet" href="/assets/a.css">))

      end # context
    end #it

    it 'initizalizes sprockets-helpers in production' do
      within_construct do |c|
        c.file 'assets/a.css'
        stub_env_vars
        ENV.stub(:[]).with('RACK_ENV').and_return("production")
        CloudCrooner.configure_sprockets_helpers
        CloudCrooner.manifest.compile('a.css')

        expect(context.asset_path('a.css')).to eq("http://my-bucket.s3.amazonaws.com/assets/#{CloudCrooner.sprockets['a.css'].digest_path}")
      end # construct
    end # it

  end # describe

  describe 'custom configuration' do

    it 'accepts a custom prefix' do
      within_construct do |c|
        CloudCrooner.configure do |config|
          config.prefix = "meow"
        end
        expect(CloudCrooner.prefix).to eq("meow")
        expect(Sprockets::Helpers.prefix).to eq("/meow")
        expect(CloudCrooner.manifest.dir).to eq(File.join(c, "public/meow"))
      end #context
    end #it

    it 'adds specified asset paths to load path' do
      within_construct do |c|
        c.file 'foo/bar.css'
        CloudCrooner.configure do |config|
          config.asset_paths = (%w(foo assets))
        end

        expect(CloudCrooner.sprockets['bar.css']).to be_an_instance_of(Sprockets::BundledAsset) 
      end
    end

    it 'can disable remote asset host' do
      CloudCrooner.remote_enabled = false
      expect(CloudCrooner.remote_enabled?).to be_false
    end

    it 'initializes sprockets-helpers when remote is disabled' do
      within_construct do |c|
        # compile the manifest and asset in dev
        c.file 'assets/a.css'
        c.directory 'public/assets'
        manifest = Sprockets::Manifest.new(CloudCrooner.sprockets, 'public/assets')
        CloudCrooner.manifest = manifest
        CloudCrooner.manifest.compile('a.css')

        # reload the app & helpers in production
        reload_crooner

        ENV.stub(:[]).with('RACK_ENV').and_return('production')
        CloudCrooner.configure do |config|
          config.manifest = manifest
          config.remote_enabled = false
        end

        expect(context.asset_path('a.css')).to eq("/assets/#{CloudCrooner.manifest.assets['a.css']}")
      end
    end

    it 'accepts a custom manifest' do
      within_construct do |c|
        manifest = Sprockets::Manifest.new(CloudCrooner.sprockets, 'foo/bar')
        CloudCrooner.configure do |config|
          config.manifest = manifest
        end

        expect(CloudCrooner.manifest.dir).to eq(File.join(c,'foo/bar'))
      end # construct
    end # it

    it 'accepts a list of assets to compile' do
      within_construct do |c|
        c.file 'assets/a.css'
        c.file 'assets/b.css'
        c.file 'assets/c.css'

        CloudCrooner.assets_to_compile = %w(a.css b.css)
        expect(CloudCrooner.assets_to_compile).to eq(%w(a.css b.css))
      end # construct
    end # it

    it "allows bucket to be set in config and overwrites ENV setting" do
      ENV.stub(:[]).with("AWS_BUCKET_NAME").and_return("test-bucket")
      ENV.stub(:has_key?).with("AWS_BUCKET_NAME").and_return(true)
      CloudCrooner.bucket_name = "foo_bucket"

      expect(CloudCrooner.bucket_name).to eq("foo_bucket")
    end

    it "allows bucket to be set in config if none in env" do
      CloudCrooner.bucket_name= "bar_bucket"

      ENV.stub(:[]).with("AWS_BUCKET_NAME").and_return(nil)
      ENV.stub(:has_key?).with("AWS_BUCKET_NAME").and_return(false)
      expect(CloudCrooner.bucket_name).to eq("bar_bucket")
    end # it

    it "allows region to be set in config if none in env" do
      CloudCrooner.region = "us-west-2"

      expect(CloudCrooner.region).to eq("us-west-2")
    end

    it "allows region to be set in config and overwrites ENV setting" do
      ENV.stub(:[]).with("AWS_REGION").and_return("eu-west-1")
      ENV.stub(:has_key?).with("AWS_REGION").and_return(true)
      CloudCrooner.region = "us-west-2"

      expect(CloudCrooner.region).to eq("us-west-2")
    end

    it "errors if config region is not valid" do
      expect{CloudCrooner.region = "el-dorado"}.to raise_error(CloudCrooner::FogSettingError)
    end

    it "allows aws_access_key_id to be set in config and overwrite ENV" do
      ENV.stub(:[]).with("AWS_ACCESS_KEY_ID").and_return("asdf123")
      ENV.stub(:has_key?).with("AWS_ACCESS_KEY_ID").and_return(true)
      CloudCrooner.aws_access_key_id = "lkjh0987"

      expect(CloudCrooner.aws_access_key_id).to eq("lkjh0987")
    end

    it "allows aws_access_key_id to be set in config if none in env" do
      ENV.stub(:[]).with("AWS_ACCESS_KEY_ID").and_return(nil)
      ENV.stub(:has_key?).with("AWS_ACCESS_KEY_ID").and_return(false)
      CloudCrooner.aws_access_key_id = "lkjh0987"

      expect(CloudCrooner.aws_access_key_id).to eq("lkjh0987")
    end

    it "allows aws_secret_access_key to be set in config and overwrite ENV" do
      ENV.stub(:[]).with("AWS_SECRET_ACCESS_KEY").and_return("secret")
      ENV.stub(:has_key?).with("AWS_SECRET_ACCESS_KEY").and_return(true)
      CloudCrooner.aws_secret_access_key = "terces"

      expect(CloudCrooner.aws_secret_access_key).to eq("terces")
    end

    it "allows secret access key to be set in config when ENV is empty" do
      ENV.stub(:[]).with("AWS_SECRET_ACCESS_KEY").and_return(nil)
      ENV.stub(:has_key?).with("AWS_SECRET_ACCESS_KEY").and_return(false)
      CloudCrooner.aws_secret_access_key = "terces"

      expect(CloudCrooner.aws_secret_access_key).to eq("terces")
    end

    it "sets the number of backups to keep" do
      CloudCrooner.configure{|config| config.backups_to_keep= 5}
      
      expect(CloudCrooner.backups_to_keep).to eq(5)
    end

  end # describe

  describe 'compiling and syncing assets' do

    it 'compiles assets' do
      within_construct do |c|
        mock_environment(c)
        CloudCrooner.assets_to_compile = ['a.css', 'b.css']
        (CloudCrooner.storage.local_compiled_assets).should == [] 
        CloudCrooner.compile_sprockets_assets

        expect(CloudCrooner.storage.local_compiled_assets).to eq(['assets/' + CloudCrooner.sprockets['a.css'].digest_path, 'assets/' + CloudCrooner.sprockets['b.css'].digest_path])
      end # construct
    end # it

    it 'compiles and syncs assets to the cloud', :moo => true do
      within_construct do |c|
        mock_environment(c)
        CloudCrooner.assets_to_compile = ['a.css', 'b.css']
        mock_fog(CloudCrooner.storage)
        CloudCrooner.sync

        expect(local_equals_remote?(CloudCrooner.storage)).to be_true
      end # construct
    end # it

    it 'compiles and does not sync assets if remote_enabled is false' do
      within_construct do |c|
        mock_environment(c)
        CloudCrooner.configure do |config|
          config.assets_to_compile = ['a.css', 'b.css']
          config.remote_enabled = false
        end
        mock_fog(CloudCrooner.storage)
        CloudCrooner.sync

        expect(local_equals_remote?(CloudCrooner.storage)).to be_false
      expect(CloudCrooner.storage.bucket.versions.first).to be_nil
      end # construct
    end # it 

  end # describe

  after(:each) do
    reload_crooner
  end
end #describe
