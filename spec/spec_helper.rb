require 'sprockets'
require 'sinatra/base'
require 'cloud_crooner'
require 'construct'
require 'securerandom'

RSpec.configure do |rconf|
  rconf.include Construct::Helpers

  def sprockets_env
    @sprockets_env ||= Sprockets::Environment.new.tap do |env|
      env.append_path 'assets'
    end
  end

  def stub_env_vars
    ENV.stub(:[]).and_return(nil)

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
        f << "meowmeow"
      end
      c.file('assets/b.js') do |f|
        f << "woofwoof"
      end

      c.file('assets/main.css') do |f|
        f << "/*\n"
        f << "*= require a\n"
        f << "*= require b\n"
        f << "*/\n"
      end
      c.file('assets/a.css') do |f|
        f << "prrprr"
      end
      c.file('assets/b.css') do |f|
        f << "grrgrr"
      end
      c.file('assets/c.css') do |f|
        f << "h1{color:blue;}\n"
        f << "h2{color:blue;}\n"
        f << "h3{color:blue;}\n"
      end
    }.call(construct)
  end
end
