require 'sprockets'
require 'sinatra/base'
require 'cloud_crooner'

describe 'configuration' do
  it 'sets defaults based on environment' do
    custom_env = Sprockets::Environment.new

    app = Class.new(Sinatra::Base) do
      set :sprockets, custom_env
      set :assets_prefix, '/static'
      set :digest_assets, true

      register Sinatra::CloudCrooner
    end

    expect CloudCrooner.config.prefix.to eq(app.settings.assets_prefix)
  end
end
