require 'spec_helper'

describe CloudCrooner do
  describe 'configuration' do
    context 'using settings from the environment' do
      context 'with defaults without manifest' do
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
          expect(@app.manifest.path).to match(/public\/static\/manifest-[\da-z]*\.json$/)
          expect(@app.manifest.dir).to eq(File.join(@app.settings.root,'public/static')) 
         end

        it "sets the prefix to the app's asset_prefix" do
          expect(Sinatra::CloudCrooner.config.prefix).to eq('/static')
        end

        it "sets location of static assets to parent dir of manifest" do
            expect(Sinatra::CloudCrooner.config.local_assets_dir).to eq(File.join(@app.settings.root, 'public/static'))
        end
      end # end with defaults without manifest

      context 'with defaults with manifest' do
        before(:each) do
          custom_env = Sprockets::Environment.new

          @app = Class.new(Sinatra::Base) do
            set :sprockets, custom_env
            set :assets_prefix, '/static'
            set :manifest, Proc.new { Sprockets::Manifest.new(sprockets, File.join(root, 'foo/bar')) }

            register Sinatra::CloudCrooner
          end
        end

        it "does not create a manifest" do
          expect(@app.manifest.path).to match(/foo\/bar\/manifest-[\da-z]*\.json/)
          expect(@app.manifest.dir).to eq(File.join(@app.root,'foo/bar'))
        end

        it "sets the location of static assets to the parent directory of the manifest", :meow =>true  do
          expect(Sinatra::CloudCrooner.config.local_assets_dir).to eq(File.dirname(@app.manifest.path))
        end
      end # end context with defaults with manifest 

      context "with custom settings" do
        it "uses the custom prefix" do
          custom_env = Sprockets::Environment.new

          app = Class.new(Sinatra::Base) do
            set :sprockets, custom_env
            set :assets_prefix, '/static'
            set :manifest, Proc.new { Sprockets::Manifest.new(sprockets, File.join(root, 'foo/bar')) }

            register Sinatra::CloudCrooner

            Sinatra::CloudCrooner.configure do |config|
              config.prefix = "/moogles"
            end
          end

            expect(Sinatra::CloudCrooner.config.prefix).to eq('/moogles')
          end

        it "does not use a custom local assets directory" do
          custom_env = Sprockets::Environment.new

          app = Class.new(Sinatra::Base) do
            set :sprockets, custom_env
            set :assets_prefix, "/static"
            set :manifest, Proc.new { Sprockets::Manifest.new(sprockets, File.join(root, 'foo/bar')) }

            register Sinatra::CloudCrooner

            Sinatra::CloudCrooner.configure do |config|
              config.local_assets_dir = "/chocobo"
            end
          end

          expect(Sinatra::CloudCrooner.config.local_assets_dir).to eq(File.dirname(app.manifest.path))
          end

      end # end context custom settings 

    end # end context using settings from the environment 
  end # end describe configuration
end

