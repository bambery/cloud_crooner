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

    it 'defaults to sync enabled' do
      expect(CloudCrooner.sync_enabled?).to be_true
    end

    it "defaults to looking for assets in 'assets' in prod" do
      expect(CloudCrooner.asset_paths).to eq(%w(assets))
    end

    it 'checks env for Amazon credentials' do
      ENV.stub(:[]).with("AWS_ACCESS_KEY_ID").and_return("asdf123")
      ENV.stub(:[]).with("AWS_SECRET_ACCESS_KEY").and_return("secret")
      ENV.stub(:has_key?).with("AWS_ACCESS_KEY_ID").and_return(true)
      ENV.stub(:has_key?).with("AWS_SECRET_ACCESS_KEY").and_return(true)

      expect(CloudCrooner.aws_access_key_id).to eq("asdf123")
      expect(CloudCrooner.aws_secret_access_key).to eq("secret")
    end # it

    it "checks env for bucket name" do
      ENV.stub(:[]).with("AWS_BUCKET_NAME").and_return("test-bucket")
      ENV.stub(:has_key?).with("AWS_BUCKET_NAME").and_return(true)

      expect(CloudCrooner.bucket_name).to eq("test-bucket")
    end #it

    it "checks env for region" do
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
      expect{CloudCrooner.region}.to raise_error(CloudCrooner::FogSettingError, "AWS Region must be set in ENV or in configure block")
    end

    it "errors if the bucket is not set" do
      ENV.stub(:[]).and_return(nil)
      expect{CloudCrooner.bucket_name}.to raise_error(CloudCrooner::FogSettingError, "Bucket name must be set in ENV or configure block")
    end

    it "errors if aws access key id is unset" do
      ENV.stub(:[]).and_return(nil)
      expect{CloudCrooner.aws_access_key_id}.to raise_error
    end
    
    it "errors if aws secret access key is unset" do
      expect{CloudCrooner.aws_secret_access_key}.to raise_error
    end

  end

  describe 'default configuration that touches filesystem' do
    # aka: these tests require constructs

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

        expect(CloudCrooner.assets_to_compile).to eq(%w(a.css))
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
        
        expect(Sprockets::Helpers.prefix).to eq('/assets')
        expect(context.stylesheet_tag('a.css')).to eq(%Q(<link rel="stylesheet" href="/assets/a.css">))
#        expect(Sprockets::Helpers.stylesheet_tag).to eq(%Q(<link rel="stylesheet" href="#{File.join(c, 'assets/a.css')}">))


      end # context
    end #it

    it 'initizalizes sprockets-helpers in production' do
      pending("once storage is tested, come back and test that links are being generated with aws")
#      within_construct do |c|
    end


  end # describe


  describe 'custom configuration' do

    it 'accepts a custom prefix' do
      pending('boo')
    end

    it 'adds specified asset paths to load path' do
      pending('stuff happens')
    end

    it 'can disable syncing' do
      pending("calling sync should do nothing, and helpers should generate links pointing to public")
    end

    it "looks for compiled assets in public when syncing is disabled in prod" do
      CloudCrooner.sync_enabled = false
      ENV.stub(:[]).with("RACK_ENV").and_return("production")
      expect(CloudCrooner.asset_paths).to eq(%w(public/assets)) 
    end

   
    it 'accepts a custom manifest' do
      pending('more stuff')
    end

  end # describe
  
#  describe 'registering the gem' do
#    context 'without manifest' do
#      before(:each) do
#
#        clear_class_instance
#        @app = Class.new(Sinatra::Base) do
#          set :sprockets, sprockets_env 
#          set :assets_prefix, '/static'
#
#          register CloudCrooner
#        end
#
#      end # end before each
#
#      it "creates a manifest " do
#        p "my class variables #{CloudCrooner.class_variables}"
#        p "my instance variables #{CloudCrooner.instance_variables}"
#        expect(@app.manifest).to be_an_instance_of(Sprockets::Manifest)
#        expect(@app.manifest.path).to match(/public\/static\/manifest-[\da-z]*\.json$/)
#        expect(@app.manifest.dir).to eq(File.join(@app.settings.root,'public/static')) 
#       end
#
#      it "sets the prefix to the app's asset_prefix" do
#        expect(CloudCrooner.config.prefix).to eq('static')
#      end
#
#      it "sets location of static assets to parent dir of manifest" do
#          expect(CloudCrooner.config.local_compiled_assets_dir).to eq(File.join(@app.settings.root, 'public/static'))
#      end
#    end # end context 
#
#    context 'with manifest' do
#      before(:each) do
#        clear_class_instance
#        @app = Class.new(Sinatra::Base) do
#          set :sprockets, sprockets_env 
#          set :assets_prefix, '/static'
#          set :manifest, Proc.new { Sprockets::Manifest.new(sprockets, File.join(root, 'foo/bar')) }
#
#          register CloudCrooner
#        end
#      end
#
#      it "does not create a manifest" do
#        expect(@app.manifest.path).to match(/foo\/bar\/manifest-[\da-z]*\.json/)
#        expect(@app.manifest.dir).to eq(File.join(@app.root,'foo/bar'))
#      end
#
#      it "sets the location of static assets to the parent directory of the manifest" do
#        expect(CloudCrooner.config.local_compiled_assets_dir).to eq(File.dirname(@app.manifest.path))
#      end
#
#    end # context 
#  end # describe 
#
#  describe "compiling assets" do
#    it 'compiles assets' do
#      within_construct do |c|
#        mock_app(c)
#        CloudCrooner.config.assets = ['a.css', 'b.css']
#
#        (CloudCrooner.storage.local_compiled_assets).should == [] 
#
#        CloudCrooner.compile_sprockets_assets
#
#        expect(CloudCrooner.storage.local_compiled_assets).to eq(['assets/' +sprockets_env['a.css'].digest_path, 'assets/' + sprockets_env['b.css'].digest_path])
#      end # construct
#    end # it
#  end
#  describe "foo bar baz" do
#    it 'syncs assets to the cloud', :moo => true do
#      within_construct do |f|
#
#        mock_app(f)
#        CloudCrooner.config.assets = ['a.css', 'b.css']
#        mock_fog(CloudCrooner.storage)
#        p "the config id in test #{CloudCrooner.config.object_id}"
#        CloudCrooner.sync
#
#        expect(CloudCrooner.storage.local_equals_remote?).to be_true
#      end # construct
#    end # it
  after(:each) do
    reload_crooner
  end
end #describe
