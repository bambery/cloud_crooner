require 'sprockets'
require 'sprockets-helpers'

module CloudCrooner

  class FogSettingError < StandardError; end
#  class MissingRequiredSetting < StandardError
#    def initialize(name)
#      @name = name
#    end
#
#    def message 
#      "Your app is missing a required setting: #{@name.to_s}"
#    end
#  end

    VALID_AWS_REGIONS = %w(
      us-west-2
      us-west-1
      eu-west-1
      ap-southeast-1
      ap-southeast-2
      ap-northeast-1
      sa-east-1
    )


  class << self

    def configure(&proc)
      yield self
      configure_sprockets_helpers
    end

    def configure_sprockets_helpers
      # if you're running fully on defaults, you must call this explicitly in config.ru if you want to use the helpers
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
      if @sprockets.nil?
        @sprockets = Sprockets::Environment.new
        asset_paths.each {|path| @sprockets.append_path(path)}
      end
      return @sprockets
    end
    attr_writer :sprockets

    def manifest
      @manifest ||= Sprockets::Manifest.new(File.join(public_folder, prefix))
    end
    attr_writer :manifest

    def prefix
      @prefix ||= 'assets'
    end

    def prefix=(val)
      #remove any slashes at beginning or end 
      @prefix = val.chomp('/').gsub(/^\//, "")
    end

    def public_folder
      @public_folder ||= 'public'
    end

    def public_folder=(val)
      #remove any slashes at beginning or end 
      @public_folder = val.chomp('/').gsub(/^\//, "")
    end

    def assets_to_compile  
      # list of assets to compile, given by their Sprocket's load path
      # defaults to every file under the prefix directory
      return @assets_to_compile if @assets_to_compile 
      files = Dir.glob(prefix + "**/*").select {|f| File.file?(f)}
      files.collect! { |f| f.gsub(/^#{prefix}\//, "") }
    end
    attr_writer :assets_to_compile

    # Region of your AWS bucket
    # Defaults to looking in ENV but can be overwritten in config block
    def region
      if @region
        return @region
      elsif !ENV.has_key?('AWS_REGION')
        raise FogSettingError, "AWS Region must be set in ENV or in configure block"
      elsif !VALID_AWS_REGIONS.include?(ENV['AWS_REGION'])
        raise FogSettingError, "Invalid region"
      end
      @region = ENV['AWS_REGION']
    end

    def region=(val)
      VALID_AWS_REGIONS.include?(val) ? @region = val : (raise FogSettingError, "Invalid region") 
    end

    def bucket_name
      #check env
    end
    attr_writer :bucket_name
    
    # AWS access id key given by Amazon, should be stored in 
    # env but can be set to be elsewhere.
    # Defaults to ENV["AWS_ACCESS_ID_KEY"]
    def aws_access_key_id
      if @aws_access_key_id
        return @aws_access_key_id
      elsif !ENV.has_key?('AWS_ACCESS_KEY_ID')
        raise FogSettingError, "access key id must be set in ENV or configure block"
      end
      @aws_access_key_id ||= ENV['AWS_ACCESS_KEY_ID']
    end
    attr_writer :aws_access_key_id
    
    # AWS secret access key given by Amazon, should be stored in env but can be set to be elsewhere
    # Defaults to ENV["AWS_SECRET_ACCESS_KEY"]
    def aws_secret_access_key 
      if @aws_secret_access_key
        return @aws_secret_access_key
      elsif !ENV.has_key?('AWS_SECRET_ACCESS_KEY')
        raise FogSettingError, "secret access key must be set in ENV or configure block"
      end
      @aws_secret_access_key ||= ENV['AWS_SECRET_ACCESS_KEY']
    end
    attr_writer :aws_secret_access_key

    def asset_paths
      @asset_paths ||= %w(assets)
    end
    attr_writer :paths

    def backups_to_keep
      @backups_to_keep ||= 2
    end
    attr_writer :backups_to_keep

    def log(msg)
      $stdout.puts msg
    end

    private

    def provider
      'AWS'
    end

    def digest
      true
    end

    def asset_host
      #TODO calculate 
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
#    def storage
#        @storage ||= Storage.new(self.config)
#    end
#    
#    def compile_sprockets_assets
#      self.config.manifest.compile(*self.config.assets)
#    end
#
#    def clean_sprockets_assets
#      self.config.manifest.clean(self.config.backups_to_keep)
#    end
#
#    def sync
#      self.compile_sprockets_assets
#      self.clean_sprockets_assets
#
#      self.storage.upload_files
#
#      if self.config.clean_up_remote?
#        self.storage.clean_remote
#      end
#    end
#
#  end
#end


#  end
#end
#

