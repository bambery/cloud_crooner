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
          config.digest = true
          if remote_enabled?
            config.asset_host = asset_host
          else  
            config.public_path = public_folder 
          end
        end
        config.environment = sprockets
        config.prefix = "/" + prefix
      end
    end

    def remote_enabled?
    # Disable this in prod if you want to serve compiled assets locally. 
      @remote_enabled.nil? ? (@remote_enabled = true) : @remote_enabled
    end

    def remote_enabled= (val)
      @remote_enabled = val if [ true, false ].include?(val)
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
      @manifest ||= Sprockets::Manifest.new(sprockets, File.join(public_folder, prefix))
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
    
    # AWS bucket name, can be stored in ENV but can be overwritten in config block
    # Defaults to ENV['AWS_BUCKET_NAME']
    def bucket_name 
      if @bucket_name
        return @bucket_name
      elsif !ENV.has_key?('AWS_BUCKET_NAME')
        raise FogSettingError, "Bucket name must be set in ENV or configure block"
      end
      @bucket_name = ENV['AWS_BUCKET_NAME'] 
    end
    attr_writer :bucket_name

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
    # logical paths to assets for use with Sprockets
    # default: everything under the prefix dir 
    # if remote is disabled, in prod it will default to public_folder/prefix to serve local static assets. 
    # note that if remote is enabled in prod that asset paths will be added, but the link helpers bypass sprockets and grab the manifest links, and will only fall back to the paths if the asset is not found in the manifest. 
      if ENV['RACK_ENV'] == 'production' && !remote_enabled?
        @asset_paths ||= [public_folder + '/' + prefix]
      end
        @asset_paths ||= [prefix] 
    end
    attr_writer :asset_paths

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
      @asset_host ||= "#{bucket_name}.s3.amazonaws.com" 
      #"s3-#{region}.amazonaws.com/#{bucket_name}"
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

