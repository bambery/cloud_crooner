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

        end # end before each

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
        before(:each) do
          custom_env = Sprockets::Environment.new

          @app = Class.new(Sinatra::Base) do
            set :sprockets, custom_env
            set :assets_prefix, '/static'
            set :manifest, Proc.new { Sprockets::Manifest.new(sprockets, File.join(root, 'foo/bar')) }

            register Sinatra::CloudCrooner
          end
        end

        it "uses the custom prefix" do
          Sinatra::CloudCrooner.config.prefix = "/moogles"

          expect(Sinatra::CloudCrooner.config.prefix).to eq('/moogles')
        end

        it "does not use a custom local assets directory" do
          Sinatra::CloudCrooner.config.local_assets_dir = "/chocobo"

          expect(Sinatra::CloudCrooner.config.local_assets_dir).to eq(File.dirname(@app.manifest.path))
        end

        end # end context custom settings 

    end # end context using settings from the environment 

    describe "cleaning up remote assets" do
      before(:each) do
        custom_env = Sprockets::Environment.new

        app = Class.new(Sinatra::Base) do
          set :sprockets, custom_env
          set :assets_prefix, "/static"

          register Sinatra::CloudCrooner
        
        end
      end

      it "defaults to true" do
        expect(Sinatra::CloudCrooner.config.clean_up_remote).to be_true
      end

      it "defaults to 2 backups" do
        expect(Sinatra::CloudCrooner.config.backups_to_keep).to eq(2)
      end

      it "can be disabled" do
        Sinatra::CloudCrooner.configure{|config| config.clean_up_remote= false}
      
        expect(Sinatra::CloudCrooner.config.clean_up_remote).to be_false 
      end
    
      it "sets the number of backups to keep" do
        Sinatra::CloudCrooner.configure{|config| config.backups_to_keep= 5}
        
        expect(Sinatra::CloudCrooner.config.backups_to_keep).to eq(5)
      end

    end # cleaning up remote assets

    describe "fog settings in env" do
      before(:each) do
        ENV.stub(:[]).with("AWS_REGION").and_return("eu-west-1")
        ENV.stub(:has_key?).with("AWS_REGION").and_return(true)
        ENV.stub(:[]).with("AWS_BUCKET_NAME").and_return("test-bucket")
        ENV.stub(:has_key?).with("AWS_BUCKET_NAME").and_return(true)
        custom_env = Sprockets::Environment.new

        app = Class.new(Sinatra::Base) do
          set :sprockets, custom_env
          set :assets_prefix, "/static"

          register Sinatra::CloudCrooner
        end
      end

      it "assigns the region" do
        expect(Sinatra::CloudCrooner.config.region).to eq("eu-west-1")
      end

      it "assigns the bucket name" do
        expect(Sinatra::CloudCrooner.config.bucket_name).to eq("test-bucket")
      end

      it "allows a custom bucket to be set" do
        Sinatra::CloudCrooner.config.bucket_name = "foo_bucket"

        expect(Sinatra::CloudCrooner.config.bucket_name).to eq("foo_bucket")
      end

    end # end before each
  end # end describe configuration
end

