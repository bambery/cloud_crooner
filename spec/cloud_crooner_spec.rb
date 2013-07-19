require 'spec_helper'

describe CloudCrooner do
  context 'configure using settings from the environment' do
    context 'with default settings and no manifest' do
      before(:each) do
        custom_env = Sprockets::Environment.new

        @app = Class.new(Sinatra::Base) do
          set :sprockets, custom_env
          set :assets_prefix, '/static'

          register Sinatra::CloudCrooner
        end

      end

      it "creates a manifest " do
        expect(@app.manifest).to be_an_instance_of(Sprockets::Manifest)
        expect(@app.manifest.path).to match(/public\/static\/manifest-[\da-z]*\.json/)
        expect(@app.manifest.dir).to eq(File.join(@app.settings.root,'public/static')) 
      end

      it "sets the prefix to the app's asset_prefix" do
        expect(Sinatra::CloudCrooner.config.prefix).to eq('/static')
      end

      it "sets the location of static assets to the parent directory of the manifest" do
          expect(Sinatra::CloudCrooner.config.local_assets_dir).to eq('public/static')
      end

      #      get rid of manifest path on config since it will be set on application level
#      it "sets manifest path to the same location as the static assets" do
#        expect CloudCrooner.config.manifest_path.to eq('public/static')
#      end

    end # end default settings and no manifest context

    context 'with a manifest that does not specify output path' do
      before(:each) do
        custom_env = Sprockets::Environment.new

        app = Class.new(Sinatra::Base) do
          set :sprockets, custom_env
          set :assets_prefix, '/static'
          set :manifest, Sprockets::Manifest.new(app.settings.sprockets, 'foo/bar')

          register Sinatra::CloudCrooner
        end
      end

      it "does not create a manifest" do
        expect(app.manifest.path).to match(/foo\/bar\/manifest-[\da-z]*\.json/)
        expect(app.manifest.dir).to eq('foo/bar')
      end

      it "sets the location of static assets to the parent directory of the manifest" do
        expect(CloudCrooner.config.local_assets_dir).to eq('foo/bar')
      end

    end # end context manifest that does not specify output path

  end
end
