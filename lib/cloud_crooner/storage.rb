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

    def local_assets 
#DEBUG      @local_assets ||= self.config.manifest.assets.values.map {|f| File.join(self.config.local_assets_dir, f)} 

    end

  end
end
