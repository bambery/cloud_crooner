require 'sprockets'
require 'sprockets-helpers'
require 'yaml'

class SprocketsSetup
  class MissingConfig << StandardError; end
  attr_reader :environment

  def initialize(opts={})

    if opts.has_key("yml")
      @yml = YAML::load(File.open(opts["yml"]))
    else 
      raise SprocketsSetup::MissingConfig
    end

    @environment = Sprockets::Environment.new
    @public_folder = 
    @manifest = Sprockets::Manifest.new(environment, 
  end

  def has_config?(key)
    if yml.has_key?(key)
      return true
    else
      raise SprocketsSetup::MissingConfig
    end
  end

end
