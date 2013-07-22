module Sinatra
  module CloudCrooner
    class Config

      class FogSettingError < StandardError; end

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

      # region of your AWS bucket, should be stored in ENV
      # while not technically required by fog, aws will complain bitterly and has a hit on efficiency
      def region
        return if @region
        if @region.nil? && ENV.has_key?('AWS_REGION') 
          VALID_AWS_REGIONS.include?(ENV['AWS_REGION']) ? (return @region = ENV['AWS_REGION']) : (raise FogSettingError, "Invalid region") 
        else 
          raise FogSettingError, "AWS Region must either be set in ENV or in configure block." 
        end
      end

      def region=(val)
        VALID_AWS_REGIONS.include?(val) ? @region = val : (raise FogSettingError, "Invalid region") 
      end

      def bucket_name 
        @bucket_name = ENV['AWS_BUCKET_NAME'] if @bucket_name.nil? && ENV.has_key?('AWS_BUCKET_NAME') 
      end
      attr_writer :bucket_name

    end
  end
end
