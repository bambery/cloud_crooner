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

    # (virtual) subdirectory for remote assets, ex "assets/".
    # Default is app's asset_prefix used by Sprockets.
    def prefix=(val)
      val.prepend("/") unless val.start_with?("/")
      @prefix = val.chomp("/") 
    end
    attr_reader :prefix

    # Path from app root of static assets as determined by the manifest. 
    # This is set automatically by configure_cloud_crooner and cannot be modified.
    def local_assets_dir=(val)
      @local_assets_dir ||= val
    end
    attr_reader :local_assets_dir

    # whether to delete remote assets which are no longer in the manifest. Default true
    def clean_up_remote 
      @clean_up_remote.nil? ? true : @clean_up_remote 
    end
    attr_writer :clean_up_remote 

    # Used with clean_up_remote: how many backups to keep for each asset in the manifest. Does not apply to assest that have been completely deleted from the file system. 
    def backups_to_keep
      @backups_to_keep ||= 2
    end
    attr_writer :backups_to_keep

    # manifest for files to upload, defaults to app's manifest
    attr_accessor :manifest

    # region of your AWS bucket, should be stored in ENV but can be overwritten in config block
    # while not technically required by fog, aws will complain bitterly and has a hit on performance 
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

    # AWS bucket name, should be stored in ENV but can be overwritten in config block
    def bucket_name 
      if @bucket_name
        return @bucket_name
      elsif !ENV.has_key?('AWS_BUCKET_NAME')
        raise FogSettingError, "Bucket name must be set in ENV or configure block"
      end
      @bucket_name = ENV['AWS_BUCKET_NAME'] 
    end
    attr_writer :bucket_name

    # TODO should allow this setting to be taken from elsewhere in case juggling multiple AWS accounts
    def aws_access_key_id
      if @aws_access_key_id
        return @aws_access_key_id
      elsif !ENV.has_key?('AWS_ACCESS_KEY_ID')
        raise FogSettingError, "AWS_ACCESS_KEY_ID must be set in ENV"
      end
      @aws_access_key_id ||= ENV['AWS_ACCESS_KEY_ID']
    end

    # TODO should allow this setting to be taken from elsewhere in case juggling multiple AWS accounts
    def aws_access_key_id=(val)
      raise FogSettingError, "AWS_ACCESS_KEY_ID is sensitive data that should not be defined where it can be checked into source control. Please set it in ENV."
    end

    # TODO should allow this setting to be taken from elsewhere in case juggling multiple AWS accounts
    def aws_secret_access_key
      if @aws_secret_access_key
        return @aws_secret_access_key
      elsif !ENV.has_key?('AWS_SECRET_ACCESS_KEY')
        raise FogSettingError, "AWS_SECRET_ACCESS_KEY must be set in ENV"
      end
      @aws_secret_access_key ||= ENV['AWS_SECRET_ACCESS_KEY']
    end

    # TODO should allow this setting to be taken from elsewhere in case juggling multiple AWS accounts
    def aws_secret_access_key=(val)
      raise FogSettingError, "AWS_SECRET_ACCESS_KEY is sensitive data that should not be defined where it can be checked into source control. Please set it in ENV."
    end

    def fog_options
      options = { :provider => "AWS", :aws_access_key_id => aws_access_key_id, :aws_secret_access_key => aws_secret_access_key, :region => region }
    end

  end
end
