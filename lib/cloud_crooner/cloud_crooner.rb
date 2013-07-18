require 'sinatra/base'
require 'sprockets'

module Sinatra
  module CloudCrooner
    def self.registered(app)
      app.set :foo, 'bar'

    end

    def with_setting(name, &block)
      p "baz" 
    end
  end

  register CloudCrooner
end
