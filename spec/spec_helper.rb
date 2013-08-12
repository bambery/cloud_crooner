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
    load 'cloud_crooner/storage.rb'
    Sprockets::Helpers.instance_variables.each do |var|
      Sprockets::Helpers.instance_variable_set var, nil
    end
   end

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

  def sample_assets(construct)
    lambda { |c|
      c.file('assets/main.js') do |f|
        f << "//= require a\n"
        f << "//= require b\n"
      end
      c.file('assets/a.js') do |f|
        f << "var pi=3.14;"
      end
      c.file('assets/b.js') do |f|
        f << "var person='John Doe';"
      end

      c.file('assets/main.css') do |f|
        f << "/*\n"
        f << "*= require a\n"
        f << "*= require b\n"
        f << "*/\n"
      end
      c.file('assets/a.css') do |f|
        f << "p { color: red; }\n"
      end
      c.file('assets/b.css') do |f|
        f << "li { color: pink; }"
      end
      c.file('assets/c.css') do |f|
        f << "h1{color:blue;}\n"
        f << "h2{color:blue;}\n"
        f << "h3{color:blue;}\n"
      end
    }.call(construct)
  end

  def local_equals_remote?(storage) 
    # the remote files are not guaranteed to be ordered
    frequency(storage.local_compiled_assets) == frequency(storage.remote_assets)
  end

  def frequency(arr)
    # http://stackoverflow.com/questions/9095017/comparing-two-arrays-in-ruby
    p = Hash.new(0)
    arr.each{ |v| p[v] += 1 }
    p
  end

  def uncompiled_assets_dir(construct)
    "#{construct}" + "/assets"
  end

  def mock_fog(storage)
    Fog.mock!
    storage.connection.directories.create(
      :key => storage.instance_variable_get(:@bucket_name),
      :public => true
    )
  end

  def mock_environment(c)
    # requires a construct
    CloudCrooner.configure do |config|
      config.bucket_name = SecureRandom.hex
    end
   stub_env_vars
   sample_assets(c)
  end

end

