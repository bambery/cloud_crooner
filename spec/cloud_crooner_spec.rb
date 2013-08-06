require 'spec_helper'

describe CloudCrooner do
  describe 'default general configuration' do

    it 'creates a sprockets environment' do 
      expect(CloudCrooner.sprockets).to be_an_instance_of(Sprockets::Environment)
    end

    it 'sets a default prefix' do
      expect(CloudCrooner.prefix).to eq("assets")
    end

    it 'sets a default public folder' do
      expect(CloudCrooner.public_folder).to eq("public")
    end

    it 'checks env for Amazon credentials' do
      ENV.stub(:[]).with("AWS_ACCESS_KEY_ID").and_return("asdf123")
      ENV.stub(:[]).with("AWS_SECRET_ACCESS_KEY").and_return("secret")
      ENV.stub(:has_key?).with("AWS_ACCESS_KEY_ID").and_return(true)
      ENV.stub(:has_key?).with("AWS_SECRET_ACCESS_KEY").and_return(true)

      expect(CloudCrooner.aws_access_key_id).to eq("asdf123")
      expect(CloudCrooner.aws_secret_access_key).to eq("secret")
    end # it
  end # describe

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
 
  end # describe


  describe 'custom configuration' do

    it 'accepts a custom prefix' do
      pending('boo')
    end

    it 'adds specified asset paths to load path' do
      pending('stuff happens')
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
