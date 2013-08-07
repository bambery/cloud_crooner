require 'sprockets'
require 'sinatra/base'
require 'cloud_crooner'
require 'construct'
require 'securerandom'
require 'sprockets-helpers'

RSpec.configure do |rconf|
  rconf.include Construct::Helpers

  def reload_crooner
    # need to unset the class instance variables
    Object.send(:remove_const, 'CloudCrooner')
    load 'cloud_crooner/cloud_crooner.rb'
  end

#  def clear_class_instance
#    CloudCrooner.instance_variable_set :@config, nil
#    CloudCrooner.instance_variable_set :@storage, nil
#  end
#
#  def sprockets_env
#    @sprockets_env ||= Sprockets::Environment.new.tap do |env|
#      env.append_path 'assets'
#    end
#  end


  # used for testing sprockets-helpers
  def context(logical_path = 'application.js', pathname = nil)
    pathname ||= Pathname.new(File.join('assets', logical_path)).expand_path
    CloudCrooner.sprockets.context_class.new CloudCrooner.sprockets, logical_path, pathname
  end


  def stub_env_vars
    ENV.stub(:has_key?).and_return(false)
    ENV.stub(:[]).and_return(nil)
    ENV.stub(:[]).with('AWS_BUCKET_NAME').and_return('my-bucket')
    ENV.stub(:has_key?).with('AWS_BUCKET_NAME').and_return(true)
    ENV.stub(:[]).with('AWS_REGION').and_return('eu-west-1')
    ENV.stub(:has_key?).with('AWS_REGION').and_return(true)
    ENV.stub(:[]).with('AWS_ACCESS_KEY_ID').and_return('asdf123')
    ENV.stub(:has_key?).with('AWS_ACCESS_KEY_ID').and_return(true)
    ENV.stub(:[]).with('AWS_SECRET_ACCESS_KEY').and_return('secret')
    ENV.stub(:has_key?).with('AWS_SECRET_ACCESS_KEY').and_return(true)
  end
#
#  def sample_assets(construct)
#    lambda { |c|
#      c.file('assets/main.js') do |f|
#        f << "//= require a\n"
#        f << "//= require b\n"
#      end
#      c.file('assets/a.js') do |f|
#        f << "meowmeow"
#      end
#      c.file('assets/b.js') do |f|
#        f << "woofwoof"
#      end
#
#      c.file('assets/main.css') do |f|
#        f << "/*\n"
#        f << "*= require a\n"
#        f << "*= require b\n"
#        f << "*/\n"
#      end
#      c.file('assets/a.css') do |f|
#        f << "prrprr\n"
#        f << "ha ha ha\n"
#      end
#      c.file('assets/b.css') do |f|
#        f << "grrgrr"
#      end
#      c.file('assets/c.css') do |f|
#        f << "h1{color:blue;}\n"
#        f << "h2{color:blue;}\n"
#        f << "h3{color:blue;}\n"
#      end
#    }.call(construct)
#  end
#
#  def mock_app(c)
#      clear_class_instance
#      sample_assets(c)
#      # need to specify manifest so construct will clean it up
#      public_folder = c.directory 'public'
#      p public_folder
#      manifest_file = c.file 'public/assets/manifest.json'
#      p manifest_file
#
#        app = Class.new(Sinatra::Base) do
#          set :sprockets, sprockets_env 
#          set :assets_prefix, '/assets'
#          set :manifest, Sprockets::Manifest.new(sprockets_env, manifest_file) 
#          set :public_folder, public_folder
#          register CloudCrooner
#        end
#    end
#
#  def uncompiled_assets_dir(construct)
#    "#{construct}" + "/assets"
#  end
#
#  def mock_fog(storage)
#    stub_env_vars
#    Fog.mock!
#    storage.config.bucket_name = SecureRandom.hex
#    storage.connection.directories.create(
#      :key => storage.config.bucket_name,
#      :public => true
#    )
#  end
#
end

