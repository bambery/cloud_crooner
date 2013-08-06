require 'sprockets'

module CloudCrooner

#  class MissingRequiredSetting < StandardError
#    def initialize(name)
#      @name = name
#    end
#
#    def message 
#      "Your app is missing a required setting: #{@name.to_s}"
#    end
#  end

  class << self

    def configure
      yield self
      configure_sprockets_helpers
    end

    def configure_sprockets_helpers
      Sprockets::Helpers.configure do |config|
        if ENV['RACK_ENV'] == "production"
          config.manifest = manifest
          config.asset_host = asset_host
          config.digest = true
          config.public_path = public_path
        end
        config.environment = sprockets
        config.prefix = "/" + prefix
      end
    end

    def sprockets
      @sprockets ||= Sprockets::Environment.new
    end
    attr_writer :sprockets

    def manifest
      @manifest ||= Sprockets::Manifest.new(File.join(public_folder, prefix))
    end
    attr_writer :manifest

    def prefix
      @prefix ||= 'assets'
    end
    attr_writer :prefix

    def public_folder
      @public_folder ||= 'public'
    end
    attr_writer :public_folder

    def assets_to_compile  
      # defaults to every file under the prefix directory
      return if @assets_to_compile 
      files = Dir.glob(prefix + "**/*").select {|f| File.file?(f)}
      files.collect { |f| f.gsub[/^prefix\//, ""] }
    end
    attr_writer :assets_to_compile

    #TODO validate
    attr_accessor :region

    attr_accessor :bucket_name

    def aws_access_key_id
      #TODO check env
    end
    attr_writer :aws_access_key_id

    def aws_secret_access_key
      #TODO check env
    end
    attr_writer :aws_secret_access_key

    def provider
      'AWS'
    end

    def digest
      true
    end

    def asset_host
      #TODO calculate 
    end

    def asset_paths
      @asset_paths ||= 'assets'
    end
    attr_writer :paths

    def clean_up_remote
      @clean_up_remote = true
    end
    attr_writer :clean_up_remote

    def backups_to_keep
      @backups_to_keep ||= 2
    end
    attr_writer :backups_to_keep

    def log(msg)
      $stdout.puts msg
    end

    def storage
        @storage ||= Storage.new(self.config)
    end
    
    def compile_sprockets_assets
      self.config.manifest.compile(*self.config.assets)
    end

    def clean_sprockets_assets
      self.config.manifest.clean(self.config.backups_to_keep)
    end

    def sync
      self.compile_sprockets_assets
      self.clean_sprockets_assets

      self.storage.upload_files

      if self.config.clean_up_remote?
        self.storage.clean_remote
      end
    end

  end
end

#    def registered(app)
#      # create a manifest if there isn't one
#      app.set :manifest, Proc.new { Sprockets::Manifest.new( sprockets, File.join( public_folder, assets_prefix )) }  unless app.settings.respond_to?(:manifest)
#      @config = Config.new
#      # these settings depend on the app
#      with_setting(app, :assets_prefix)  { |value| config.prefix = value }
#      with_setting(app, :manifest)       { |value| config.local_compiled_assets_dir = value.dir }
#      with_setting(app, :manifest)       { |value| config.manifest = value }
#      with_setting(app, :public_folder) { |value| config.public_path = value }
#    end
#
#    def with_setting(app, name, &proc)
#      raise MissingRequiredSetting.new(name) unless app.settings.respond_to?(name)
#
#      val = app.settings.__send__(name)
#      yield val unless val.nil? 
#    end
#
#    def config=(data)
#      @config = data
#    end
#
#    def config
#      @config ||= Config.new
#      @config
#    end
#
#    def configure(&proc)
#      @config ||= Config.new
#      yield @config
#    end
#
#    def log(msg)
#      $stdout.puts msg
#    end
#
#  end
#end
#

