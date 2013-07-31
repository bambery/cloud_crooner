require 'sprockets'

module CloudCrooner
  class FogSettingError < StandardError; end

  class Config

    # Any settings that depend on app settings are assigned in cloud_crooner.rb in the configure_cloud_crooner method. Other defaults are set here.

    VALID_AWS_REGIONS = %w(
      us-west-2
      us-west-1
      eu-west-1
      ap-southeast-1
      ap-southeast-2
      ap-northeast-1
      sa-east-1
    )

    # (virtual) subdirectory for remote assets, ex "/assets".
    # Default is app's asset_prefix used by Sprockets and can't be changed.
    # set in CloudCrooner::registered 
    def prefix=(val)
      @prefix ||= val 
    end
    attr_reader :prefix

    # Path from app root of static assets as determined by the manifest. 
    def local_compiled_assets_dir
      @local_compiled_assets_dir ||= manifest.dir
    end

    # whether to delete remote assets (and backups) which are no longer in the manifest. Default true
    def clean_up_remote? 
      @clean_up_remote.nil? ? true : @clean_up_remote 
    end
    attr_writer :clean_up_remote

    # Used with clean_up_remote: how many backups to keep for each asset in the manifest. Does not apply to assets that have been completely deleted from the file system. 
    def backups_to_keep
      @backups_to_keep ||= 2
    end
    attr_writer :backups_to_keep

    # defaults to app's public_folder 
    # set in CloudCrooner::registered 
    attr_accessor :public_path

    # manifest for files to upload, defaults to app's manifest
    # set in CloudCrooner::registered 
    attr_accessor :manifest

    # region of your AWS bucket, should be stored in ENV but can be overwritten in config block
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

    # AWS access id key given by Amazon, should be stored in env but can be set to be elsewhere
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

    def fog_options
      options = { :provider => "AWS", :aws_access_key_id => aws_access_key_id, :aws_secret_access_key => aws_secret_access_key, :region => region }
    end

    def asset_host
      "s3-#{region}.amazonaws.com/#{bucket_name}"
    end

  end
end
