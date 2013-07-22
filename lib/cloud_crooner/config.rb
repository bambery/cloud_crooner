module Sinatra
  module CloudCrooner
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
      # This is set once automatically by configure_cloud_crooner and cannot be modified.
      def local_assets_dir=(val)
        @local_assets_dir ||= val
      end
      attr_reader :local_assets_dir

      # whether to delete remote assets which are no longer in the manifest 
      def clean_up_remote 
        @clean_up_remote.nil? ? true : @clean_up_remote 
      end
      attr_writer :clean_up_remote 

    end
  end
end
