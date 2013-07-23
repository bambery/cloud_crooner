require 'spec_helper'

describe CloudCrooner::Storage do
  it "initializes from config" do
    config = {:region => 'eu-west-1', :aws_secret_access_key => 'secret', :aws_access_key_id => 'asdf123', :provider => 'AWS'}
    storage = CloudCrooner::Storage.new(config)
  end

#  before(:each) do
#    custom_env = Sprockets::Environment.new 
#
#    @app = Class.new(Sinatra::Base) do
#      set :sprockets, custom_env
#      set :assets_prefix, '/assets'
#    end
#
#    register Sinatra::CloudCrooner
#  
#
#  end
end
