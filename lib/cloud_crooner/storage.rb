require 'fog'

module CloudCrooner
  class Storage
    attr_accessor :config
  end

  def initialize(cfg)
    @config = cfg
  end

  def connection
    @connection ||= Fog::Storage.new(self.config.fog_options)
  end
end
