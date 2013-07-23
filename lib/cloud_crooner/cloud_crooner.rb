require 'sprockets'

module CloudCrooner

  class MissingRequiredSetting < StandardError
    def initialize(name)
      @name = name
    end

    def message 
      "Your app is missing a required setting: #{@name.to_s}"
    end
  end


  def configure_cloud_crooner(&proc)
    CloudCrooner.configure do |config|
      with_setting(:assets_prefix) { |value| config.prefix = value }
      with_setting(:manifest) { |value| config.local_assets_dir = value.dir}
      with_setting(:manifest) { |value| config.manifest = value }
    end
  end

  def with_setting(name, &proc)
    raise MissingRequiredSetting.new(name) unless settings.respond_to?(name)

    val = settings.__send__(name)
    yield val unless val.nil? 
  end

  class << self
    def registered(app)
      # create a manifest if there isn't one
      app.set :manifest, Proc.new { Sprockets::Manifest.new( sprockets, File.join( public_folder, assets_prefix )) }  unless app.settings.respond_to?(:manifest)
      @config = Config.new
      app.configure_cloud_crooner
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


