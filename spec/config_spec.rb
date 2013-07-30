require 'spec_helper'

describe CloudCrooner do
  describe 'configuration' do
    context 'auto settings from the environment' do
      context 'without manifest' do
        before(:each) do
          custom_env = Sprockets::Environment.new

          @app = Class.new(Sinatra::Base) do
            set :sprockets, custom_env
            set :assets_prefix, '/static'

            register CloudCrooner
          end

        end # end before each

        it "creates a manifest " do
          expect(@app.manifest).to be_an_instance_of(Sprockets::Manifest)
          expect(@app.manifest.path).to match(/public\/static\/manifest-[\da-z]*\.json$/)
          expect(@app.manifest.dir).to eq(File.join(@app.settings.root,'public/static')) 
         end

        it "sets the prefix to the app's asset_prefix" do
          expect(CloudCrooner.config.prefix).to eq('/static')
        end

        it "sets location of static assets to parent dir of manifest" do
            expect(CloudCrooner.config.local_compiled_assets_dir).to eq(File.join(@app.settings.root, 'public/static'))
        end
      end # end with defaults without manifest

      context 'with manifest' do
        before(:each) do
          custom_env = Sprockets::Environment.new

          @app = Class.new(Sinatra::Base) do
            set :sprockets, custom_env
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
      end # end context with defaults with manifest 
    end # end context using settings from the environment 

    describe "cleaning up remote assets" do
      before(:each) do
        custom_env = Sprockets::Environment.new

        app = Class.new(Sinatra::Base) do
          set :sprockets, custom_env
          set :assets_prefix, "/static"

          register CloudCrooner
        
        end
      end

      it "defaults to true" do
        expect(CloudCrooner.config.clean_up_remote?).to be_true
      end

      it "defaults to 2 backups" do
        expect(CloudCrooner.config.backups_to_keep).to eq(2)
      end

      it "can be disabled" do
        CloudCrooner.configure{|config| config.clean_up_remote= false}
      
        expect(CloudCrooner.config.clean_up_remote?).to be_false 
      end
    
      it "sets the number of backups to keep" do
        CloudCrooner.configure{|config| config.backups_to_keep= 5}
        
        expect(CloudCrooner.config.backups_to_keep).to eq(5)
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

          register CloudCrooner
        end
      end

      describe "region" do
        it "defaults to checking ENV['AWS_REGION']" do
          ENV.stub(:[]).with("AWS_REGION").and_return("eu-west-1")
          ENV.stub(:has_key?).with("AWS_REGION").and_return(true)

          expect(CloudCrooner.config.region).to eq("eu-west-1")
        end

        it "errors if the ENV region is not valid" do
          ENV.stub(:[]).with("AWS_REGION").and_return("shangrila")
          ENV.stub(:has_key?).with("AWS_REGION").and_return(true)

          expect{CloudCrooner.config.region}.to raise_error(CloudCrooner::FogSettingError)
        end

        it "allows region to be set in config if none in env" do
          CloudCrooner.config.region = "us-west-2"

          expect(CloudCrooner.config.region).to eq("us-west-2")
        end

        it "allows region to be set in config and overwrites ENV setting" do
          ENV.stub(:[]).with("AWS_REGION").and_return("eu-west-1")
          ENV.stub(:has_key?).with("AWS_REGION").and_return(true)
          CloudCrooner.config.region = "us-west-2"

          expect(CloudCrooner.config.region).to eq("us-west-2")
        end

        it "errors if config region is not valid" do
          expect{CloudCrooner.config.region = "el-dorado"}.to raise_error(CloudCrooner::FogSettingError)
        end

        it "errors if region is not assigned" do
          expect{CloudCrooner.config.region}.to raise_error(CloudCrooner::FogSettingError, "AWS Region must be set in ENV or in configure block")
        end
      end # end region

      describe "bucket name" do

        it "assigns from ENV" do
          ENV.stub(:[]).with("AWS_BUCKET_NAME").and_return("test-bucket")
          ENV.stub(:has_key?).with("AWS_BUCKET_NAME").and_return(true)

          expect(CloudCrooner.config.bucket_name).to eq("test-bucket")
        end

        it "allows bucket to be set in config and overwrites ENV setting" do
          ENV.stub(:[]).with("AWS_BUCKET_NAME").and_return("test-bucket")
          ENV.stub(:has_key?).with("AWS_BUCKET_NAME").and_return(true)
          CloudCrooner.config.bucket_name = "foo_bucket"

          expect(CloudCrooner.config.bucket_name).to eq("foo_bucket")
        end

        it "allows bucket to be set in config if none in env" do
          CloudCrooner.config.bucket_name= "bar_bucket"

          expect(CloudCrooner.config.bucket_name).to eq("bar_bucket")
        end

        it "errors if the bucket is not set" do
          expect{CloudCrooner.config.bucket_name}.to raise_error(CloudCrooner::FogSettingError, "Bucket name must be set in ENV or configure block")
        end

      end # bucket name

      describe "AWS access key id" do
        it "is set from ENV['AWS_ACCESS_KEY_ID'] by default" do
          ENV.stub(:[]).with("AWS_ACCESS_KEY_ID").and_return("asdf123")
          ENV.stub(:has_key?).with("AWS_ACCESS_KEY_ID").and_return(true)

          expect(CloudCrooner.config.aws_access_key_id).to eq("asdf123")
        end

        it "is set in config and overwrites ENV" do
          ENV.stub(:[]).with("AWS_ACCESS_KEY_ID").and_return("asdf123")
          ENV.stub(:has_key?).with("AWS_ACCESS_KEY_ID").and_return(true)
          CloudCrooner.config.aws_access_key_id = "lkjh0987"

          expect(CloudCrooner.config.aws_access_key_id).to eq("lkjh0987")
        end

        it "allows access key id to be set in config if none in env" do
          CloudCrooner.config.aws_access_key_id = "lkjh0987"

          expect(CloudCrooner.config.aws_access_key_id).to eq("lkjh0987")
        end

        it "errors if unset" do
          expect{CloudCrooner.config.aws_access_key_id}.to raise_error
        end
      end # aws access key id

      describe "AWS secret access key" do
        it "set from ENV['AWS_SECRET_ACCESS_KEY'] by default" do
          ENV.stub(:[]).with("AWS_SECRET_ACCESS_KEY").and_return("secret")
          ENV.stub(:has_key?).with("AWS_SECRET_ACCESS_KEY").and_return(true)

          expect(CloudCrooner.config.aws_secret_access_key).to eq("secret")
        end

        it "is set in config and overwrites ENV" do
          ENV.stub(:[]).with("AWS_SECRET_ACCESS_KEY").and_return("secret")
          ENV.stub(:has_key?).with("AWS_SECRET_ACCESS_KEY").and_return(true)
          CloudCrooner.config.aws_secret_access_key = "terces"

          expect(CloudCrooner.config.aws_secret_access_key).to eq("terces")
        end

        it "allows secret access key to be set in config when ENV is empty" do
          CloudCrooner.config.aws_secret_access_key = "terces"

          expect(CloudCrooner.config.aws_secret_access_key).to eq("terces")
        end

        it "errors if unset" do
          expect{CloudCrooner.config.aws_secret_access_key}.to raise_error
        end

      end # end aws secret access key

      it 'gathers the fog options from the config' do
        ENV.stub(:[]).with('AWS_REGION').and_return('eu-west-1')
        ENV.stub(:has_key?).with('AWS_REGION').and_return(true)
        ENV.stub(:[]).with('AWS_ACCESS_KEY_ID').and_return('asdf123')
        ENV.stub(:has_key?).with('AWS_ACCESS_KEY_ID').and_return(true)
        ENV.stub(:[]).with('AWS_SECRET_ACCESS_KEY').and_return('secret')
        ENV.stub(:has_key?).with('AWS_SECRET_ACCESS_KEY').and_return(true)

        expect(CloudCrooner.config.fog_options[:region]).to eq('eu-west-1')
        expect(CloudCrooner.config.fog_options[:provider]).to eq('AWS')
        expect(CloudCrooner.config.fog_options[:aws_access_key_id]).to eq('asdf123')
        expect(CloudCrooner.config.fog_options[:aws_secret_access_key]).to eq('secret')
      end # end fog options

    end # end fog configuration 
  end # end describe configuration
end

