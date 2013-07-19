require 'sprockets'

module Sinatra
  module CloudCrooner

    class MissingRequiredSetting < StandardError; end 

    def configure_cloud_crooner(&proc)
      CloudCrooner.configure do |config|
        with_setting(:assets_prefix) { |value| config.prefix = value }
        with_setting(:manifest) { |value| config.local_assets_dir = value.dir}

      end
    end

    def with_setting(name, &proc)
      raise MissingRequiredSetting unless settings.respond_to?(name)

      val = settings.__send__(name)
      yield val unless val.nil? 
    end

    class << self
      def registered(foo)
        # create a manifest if there isn't one
        foo.set :manifest, Proc.new { Sprockets::Manifest.new( sprockets, File.join( public_folder, assets_prefix )) }  unless foo.respond_to?(:manifest)
        foo.configure_cloud_crooner
      end

      def config=(data)
        @config = data
      end

      def config
        @config ||= Config.new
        @config
      end

      def configure(&proc)
        @config ||= Config.new
        yield @config
      end

    end
  end
end


