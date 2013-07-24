require 'sprockets'
require 'sinatra/base'
require 'cloud_crooner'
require 'construct'

RSpec.configure do |rconf|
  rconf.include Construct::Helpers

  def sprockets_env
    @sprockets_env ||= Sprockets::Environment.new.tap do |env|
#DEBUG      env.append_path 'assets' if File.directory?('assets')
      env.append_path 'assets'
    end
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
    }.call(construct)
  end
end
