require 'sinatra/base'
require 'sprockets'

module Sinatra
  module CloudCrooner

    class MissingAssetPrefix < StandardError; end 

    def configure_cloud_crooner(&proc)
      CloudCrooner.configure do |config|
        with_setting(:assets_prefix) { |value| config.prefix = value }

      end
    end

    def with_setting(name, &proc)
      raise MissingAssetPrefix unless settings.respond_to?(name)

      val = settings.send(name)
      yield val unless val.nil? 
    end

    class << self
      def registered(app)
        # create a manifest if there isn't one
        app.set :manifest, Sprockets::Manifest.new(app.settings.sprockets, File.join(app.settings.public_folder, app.settings.assets_prefix)) unless app.respond_to?(:manifest)

      end

      def config=(data)
        @config = data
      end

      def config
        @config ||= Config.new
      end

      def configure(&proc)
        @config ||= Config.new
        yield @config
      end

    end
  end

  register CloudCrooner
end


