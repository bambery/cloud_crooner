require 'spec_helper'

describe CloudCrooner do
  it 'compiles assets' do
    within_construct do |c|
      mock_app(c)
      CloudCrooner.config.assets = ['a.css', 'b.css']

      (CloudCrooner.storage.local_compiled_assets).should == [] 

      CloudCrooner.compile_sprockets_assets

      expect(CloudCrooner.storage.local_compiled_assets).to eq(['assets/' +sprockets_env['a.css'].digest_path, 'assets/' + sprockets_env['b.css'].digest_path])
    end # construct
  end # it
end #describe
