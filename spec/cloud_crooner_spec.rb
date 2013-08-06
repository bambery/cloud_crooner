require 'spec_helper'

describe CloudCrooner do
  describe 'registering the gem' do
    context 'without manifest' do
      before(:each) do

        clear_class_instance
        @app = Class.new(Sinatra::Base) do
          set :sprockets, sprockets_env 
          set :assets_prefix, '/static'

          register CloudCrooner
        end

      end # end before each

      it "creates a manifest " do
        p "my class variables #{CloudCrooner.class_variables}"
        p "my instance variables #{CloudCrooner.instance_variables}"
        expect(@app.manifest).to be_an_instance_of(Sprockets::Manifest)
        expect(@app.manifest.path).to match(/public\/static\/manifest-[\da-z]*\.json$/)
        expect(@app.manifest.dir).to eq(File.join(@app.settings.root,'public/static')) 
       end

      it "sets the prefix to the app's asset_prefix" do
        expect(CloudCrooner.config.prefix).to eq('static')
      end

      it "sets location of static assets to parent dir of manifest" do
          expect(CloudCrooner.config.local_compiled_assets_dir).to eq(File.join(@app.settings.root, 'public/static'))
      end
    end # end context 

    context 'with manifest' do
      before(:each) do
        clear_class_instance
        @app = Class.new(Sinatra::Base) do
          set :sprockets, sprockets_env 
          set :assets_prefix, '/static'
          set :manifest, Proc.new { Sprockets::Manifest.new(sprockets, File.join(root, 'foo/bar')) }

          register CloudCrooner
        end
      end

      it "does not create a manifest" do
        expect(@app.manifest.path).to match(/foo\/bar\/manifest-[\da-z]*\.json/)
        expect(@app.manifest.dir).to eq(File.join(@app.root,'foo/bar'))
      end

      it "sets the location of static assets to the parent directory of the manifest" do
        expect(CloudCrooner.config.local_compiled_assets_dir).to eq(File.dirname(@app.manifest.path))
      end

    end # context 
  end # describe 

  describe "compiling assets" do
    it 'compiles assets' do
      within_construct do |c|
        mock_app(c)
        CloudCrooner.config.assets = ['a.css', 'b.css']

        (CloudCrooner.storage.local_compiled_assets).should == [] 

        CloudCrooner.compile_sprockets_assets

        expect(CloudCrooner.storage.local_compiled_assets).to eq(['assets/' +sprockets_env['a.css'].digest_path, 'assets/' + sprockets_env['b.css'].digest_path])
      end # construct
    end # it
  end
  describe "foo bar baz" do
    it 'syncs assets to the cloud', :moo => true do
      within_construct do |f|

        mock_app(f)
        CloudCrooner.config.assets = ['a.css', 'b.css']
        mock_fog(CloudCrooner.storage)
        p "the config id in test #{CloudCrooner.config.object_id}"
        CloudCrooner.sync

        expect(CloudCrooner.storage.local_equals_remote?).to be_true
      end # construct
    end # it
  end
  end #describe
