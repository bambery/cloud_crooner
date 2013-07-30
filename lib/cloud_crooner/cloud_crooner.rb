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

  class << self
    def registered(app)
      # create a manifest if there isn't one
      app.set :manifest, Proc.new { Sprockets::Manifest.new( sprockets, File.join( public_folder, assets_prefix )) }  unless app.settings.respond_to?(:manifest)
      @config = Config.new
      # these settings depend on the app
      with_setting(app, :assets_prefix)  { |value| config.sprockets_prefix = value }
      with_setting(app, :manifest)       { |value| config.manifest = value }
      with_setting(app, :public_folder) { |value| config.public_path = value }
    end

    def with_setting(app, name, &proc)
      raise MissingRequiredSetting.new(name) unless app.settings.respond_to?(name)

      val = app.settings.__send__(name)
      yield val unless val.nil? 
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

    def log(msg)
      $stdout.puts msg
    end

  end
end


