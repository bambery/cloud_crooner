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
        ENV.stub(:has_key?).and_return(false)
        ENV.stub(:[]).and_return(nil)

        custom_env = Sprockets::Environment.new

        app = Class.new(Sinatra::Base) do
          set :sprockets, custom_env
          set :assets_prefix, "/static"

          register Sinatra::CloudCrooner
        end
      end

      context "region" do
        it "assigns from ENV" do
          ENV.stub(:[]).with("AWS_REGION").and_return("eu-west-1")
          ENV.stub(:has_key?).with("AWS_REGION").and_return(true)

          expect(Sinatra::CloudCrooner.config.region).to eq("eu-west-1")
        end

        it "errors if the ENV region is not valid" do
          ENV.stub(:[]).with("AWS_REGION").and_return("shangrila")
          ENV.stub(:has_key?).with("AWS_REGION").and_return(true)

          expect{Sinatra::CloudCrooner.config.region}.to raise_error(Sinatra::CloudCrooner::FogSettingError)
        end

        it "allows region to be set in config if none in env" do
          Sinatra::CloudCrooner.config.region = "us-west-2"

          expect(Sinatra::CloudCrooner.config.region).to eq("us-west-2")
        end

        it "allows region to be set in config and overwrites ENV setting" do
          ENV.stub(:[]).with("AWS_REGION").and_return("eu-west-1")
          ENV.stub(:has_key?).with("AWS_REGION").and_return(true)
          Sinatra::CloudCrooner.config.region = "us-west-2"

          expect(Sinatra::CloudCrooner.config.region).to eq("us-west-2")
        end

        it "errors if config region is not valid" do
          expect{Sinatra::CloudCrooner.config.region = "el-dorado"}.to raise_error(Sinatra::CloudCrooner::FogSettingError)
        end

        it "errors if region is not assigned" do
          expect{Sinatra::CloudCrooner.config.region}.to raise_error(Sinatra::CloudCrooner::FogSettingError, "AWS Region must be set in ENV or in configure block")
        end
      end # end region

      context "bucket name" do

        it "assigns from ENV" do
          ENV.stub(:[]).with("AWS_BUCKET_NAME").and_return("test-bucket")
          ENV.stub(:has_key?).with("AWS_BUCKET_NAME").and_return(true)

          expect(Sinatra::CloudCrooner.config.bucket_name).to eq("test-bucket")
        end

        it "allows bucket to be set in config and overwrites ENV setting" do
          ENV.stub(:[]).with("AWS_BUCKET_NAME").and_return("test-bucket")
          ENV.stub(:has_key?).with("AWS_BUCKET_NAME").and_return(true)
          Sinatra::CloudCrooner.config.bucket_name = "foo_bucket"

          expect(Sinatra::CloudCrooner.config.bucket_name).to eq("foo_bucket")
        end

        it "allows bucket to be set in config if none in env" do
          Sinatra::CloudCrooner.config.bucket_name= "bar_bucket"

          expect(Sinatra::CloudCrooner.config.bucket_name).to eq("bar_bucket")
        end

        it "errors if the bucket is not set" do
          expect{Sinatra::CloudCrooner.config.bucket_name}.to raise_error(Sinatra::CloudCrooner::FogSettingError, "Bucket name must be set in ENV or configure block")
        end

      end # bucket name

      context "AWS access key id" do
        it "set from ENV" do
          ENV.stub(:[]).with("AWS_ACCESS_KEY_ID").and_return("asdf123")
          ENV.stub(:has_key?).with("AWS_ACCESS_KEY_ID").and_return(true)

          expect(Sinatra::CloudCrooner.config.aws_access_key_id).to eq("asdf123")
        end

        it "cannot be set from config" do
          expect{Sinatra::CloudCrooner.config.aws_access_key_id = "xyz098"}.to raise_error(Sinatra::CloudCrooner::FogSettingError) 
        end

        it "errors if missing from ENV" do
          expect{Sinatra::CloudCrooner.config.aws_access_key_id}.to raise_error
        end
      end # aws access key id

      context "AWS secret access key" do
        it "set from ENV" do
          ENV.stub(:[]).with("AWS_SECRET_ACCESS_KEY").and_return("secret")
          ENV.stub(:has_key?).with("AWS_SECRET_ACCESS_KEY").and_return(true)

          expect(Sinatra::CloudCrooner.config.aws_secret_access_key).to eq("secret")
        end

        it "cannot be set from config" do
          expect{Sinatra::CloudCrooner.config.aws_secret_access_key = "terces"}.to raise_error(Sinatra::CloudCrooner::FogSettingError) 
        end

        it "errors if missing from ENV" do
          expect{Sinatra::CloudCrooner.config.aws_secret_access_key}.to raise_error
        end

      end # end aws secret access key

    end # end fog configuration 
  end # end describe configuration
end

