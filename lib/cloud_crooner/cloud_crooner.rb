require 'sprockets'
require 'sprockets-helpers'

module CloudCrooner

  class FogSettingError < StandardError; end

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

    ##
    # Convinience method for setting options and configuring helpers
    # 
    def configure(&proc)
      yield self
      configure_sprockets_helpers
    end

    ##
    # Set up the helpers to properly link to assets in current environment.
    #
    # If you're running fully on defaults, you must call this explicitly in 
    # config.ru if you want to use the helpers
    #
    def configure_sprockets_helpers
      Sprockets::Helpers.configure do |config|
        case serve_assets
        when "remote"
          config.manifest = manifest
          config.digest = digest 
          config.debug = false
          config.asset_host = asset_host
        when "local_static" 
          config.manifest = manifest
          config.digest = digest 
          config.debug - false
          config.public_path = public_folder 
        end
        config.environment = sprockets
        config.prefix = "/" + prefix
      end
    end

    ##
    #  Returns the Storage instance
    #
    def storage
      @storage ||= Storage.new
    end
    
    ##
    # Where to serve assets from
    # * "local_dynamic" : default in dev and test - serves assets from sprockets
    # * "local_static"  : serves compiled assets from public_folder 
    # * "remote"        : default in prod - serves compiled assets from S3
    # 
    def serve_assets
     if ENV['RACK_ENV'] == "production"
        @serve_assets.nil ? @serve_assets = "remote" : @serve_assets
      elsif @serve_assets.nil?
        @serve_assets = "local_dynamic"
      else
        @serve_assets
      end
    end

    def serve_assets= (val)
      @serve_assets =  val if [ "local_dynamic", 
                                "local_static", 
                                "remote" ].include?(val)
    end

    ##
    # Returns or creates the Sprockets instance and adds asset_paths to the 
    # Sprockets load path.
    #
    def sprockets
      if @sprockets.nil?
        @sprockets = Sprockets::Environment.new { |env| env.logger = Logger.new($stdout) }
        asset_paths.each {|path| @sprockets.append_path(path)}
      end
      return @sprockets
    end
    attr_writer :sprockets

    ##
    # Returns or creates the Sprockets manifest in public_folder/prefix.
    #
    def manifest
      @manifest ||= Sprockets::Manifest.new(sprockets, File.join(public_folder, prefix))
    end
    attr_writer :manifest

    ##
    # Path from root to dynamic assets base folder. By default '/assets'. 
    #
    # Also serves as the prefix under which S3 assets will be stored.
    # Paths to assets from the helpers will look something like 
    # 'http://bucket-name.s3.amazonaws.com/prefix/filename'.
    #
    def prefix
      @prefix ||= 'assets'
    end

    def prefix=(val)
      #remove any slashes at beginning or end 
      @prefix = val.chomp('/').gsub(/^\//, "")
    end

    ##
    # The public folder of the application. By default '/public'. If a  
    # different folder is set, it must also be set on the Sinatra app.
    #
    def public_folder
      @public_folder ||= 'public'
    end

    def public_folder=(val)
      #remove any slashes at beginning or end 
      @public_folder = val.chomp('/').gsub(/^\//, "")
    end

    ##
    # The list of assets to compile, given by their Sprocket's load path.
    # Defaults to every file under the prefix directory.
    #
    def assets_to_compile  
      return @assets_to_compile if @assets_to_compile 
      files = Dir.glob(prefix + "**/*").select {|f| File.file?(f)}
      files.collect! { |f| f.gsub(/^#{prefix}\//, "") }
    end
    attr_writer :assets_to_compile
    
    ##
    # AWS bucket name. Defaults to ENV['AWS_BUCKET_NAME'] but can be 
    # overridden in config block. Required if using S3.
    #
    def bucket_name 
      if @bucket_name
        return @bucket_name
      elsif !ENV.has_key?('AWS_BUCKET_NAME')
        raise FogSettingError, "Bucket name must be set in ENV or configure block"
      end
      @bucket_name = ENV['AWS_BUCKET_NAME'] 
    end
    attr_writer :bucket_name

    ##
    # Region of AWS bucket. Defaults to ENV['AWS_REGION'] but can 
    # be overridden in config block. Must be a valid AWS region. Required
    # if using S3.
    #
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

    ##
    # AWS access id key given by Amazon. Defaults to ENV['AWS_ACCESS_KEY_ID'] 
    # but can be overridden in config block. Required if using S3.
    #
    # Do not set value directly in app, store outside in a non-source 
    # controlled location.
    #
    def aws_access_key_id
      if @aws_access_key_id
        return @aws_access_key_id
      elsif !ENV.has_key?('AWS_ACCESS_KEY_ID')
        raise FogSettingError, "access key id must be set in ENV or configure block"
      end
      @aws_access_key_id ||= ENV['AWS_ACCESS_KEY_ID']
    end
    attr_writer :aws_access_key_id
    
    ##
    # AWS secret access key given by Amazon. Defaults to 
    # ENV['AWS_SECRET_ACCESS_KEY'] but can be overridden in config block. 
    # Required if using S3.
    #
    # Do not set value directly in app, store outside in a non-source 
    # controlled location.
    #
    def aws_secret_access_key 
      if @aws_secret_access_key
        return @aws_secret_access_key
      elsif !ENV.has_key?('AWS_SECRET_ACCESS_KEY')
        raise FogSettingError, "secret access key must be set in ENV or configure block"
      end
      @aws_secret_access_key ||= ENV['AWS_SECRET_ACCESS_KEY']
    end
    attr_writer :aws_secret_access_key

    ##
    # Logical paths to assets for use with Sprockets. Defaults to "prefix" 
    # dir. 
    # If serve_assets is set to "remote" or "local_static", paths will be 
    # added, but the link helpers bypass Sprockets and grab the manifest 
    # links, and will only fall back to the paths if the asset is not found in 
    # the manifest. 
    # 
    def asset_paths
      @asset_paths ||= [prefix] 
    end
    attr_writer :asset_paths

    ##
    # Number of compiled assets to keep as backups. Default is 2. 
    #
    def backups_to_keep
      @backups_to_keep ||= 2
    end
    attr_writer :backups_to_keep

    ##
    # Passed to Fog gem when creating a Storage instance 
    #
    def fog_options
      options = { 
                  :provider => provider, 
                  :aws_access_key_id => aws_access_key_id, 
                  :aws_secret_access_key => aws_secret_access_key, 
                  :region => region 
                }
    end

    ##
    # Compile the assets given in "assets_to_compile". Outputs to the directory
    # of the manifest. Updates the manifest.
    #
    def compile_sprockets_assets
      manifest.compile(*self.assets_to_compile)
    end

    ##
    # If there are more than the set number of compiled asset backups, the 
    # oldest asset will be deleted locally and removed from the manifest.
    #
    def clean_sprockets_assets
      manifest.clean(backups_to_keep)
    end

    ##
    # Delete the manifest's containing directory and everything in it.
    #
    def clobber_sprockets_assets
      manifest.clobber
    end

    ##
    # Compile assets locally and remove old local backups. If serve_assets is  
    # "remote", it will upload changed files and delete old remote backups.
    #
    def sync
      compile_sprockets_assets
      clean_sprockets_assets

      if serve_assets == "remote" 
        storage.upload_files
        storage.clean_remote
      end

    end

    ##
    # Output logging messages to stdout
    #
    def log(msg)
      $stdout.puts msg
    end

    private

    ##
    # Used with Fog to set the remote asset host. Allows for expansion into 
    # other cloud providers.
    #
    def provider
      'AWS'
    end

    ## 
    # Used with Sprockets Helpers to link to compiled (digest) or uncompiled 
    # assets (non digest). False if serving local uncompiled assets. 
    #
    def digest
      serve_assets == "local_dynamic" ? false : true 
    end

    ##
    # Used with Sprockets Helpers to link to remote assets
    #
    def asset_host
      @asset_host ||= "#{bucket_name}.s3.amazonaws.com" 
    end

  end
end
