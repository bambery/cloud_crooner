require 'fog'

module CloudCrooner
  class Storage
    attr_accessor :config

    def initialize(cfg)
      @config = cfg
    end

    def connection
      @connection ||= Fog::Storage.new(self.config.fog_options)
    end

    def bucket
      @bucket ||= connection.directories.get(self.config.bucket_name, :prefix => self.config.prefix)
    end

    def files_to_upload
      

    end

  end
end
