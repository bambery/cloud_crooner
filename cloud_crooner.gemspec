# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloud_crooner/version'

Gem::Specification.new do |spec|
  spec.name          = "cloud_crooner"
  spec.version       = CloudCrooner::VERSION
  spec.authors       = ["bambery"]
  spec.email         = ["lwszolek@gmail.com"]
  spec.description   = %q{Manage assets on Sinatra apps with Sprockets and S3}
  spec.summary       = %q{Manage assets with Sprockets, precompile them into static assets, then upload them to S3}
  spec.homepage      = "https://github.com/bambery/cloud_crooner"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "sinatra"
  spec.add_development_dependency "test-construct"

  spec.add_dependency             "sprockets", "~>2.10"
  spec.add_dependency             "fog", "~> 1.12" 
  spec.add_dependency             "sprockets-helpers"
end
