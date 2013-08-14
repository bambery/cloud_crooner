# CloudCrooner

Manage your Sinatra app's assets with [Sprockets](https://github.com/sstephenson/sprockets) and sync them with [Amazon S3](http://aws.amazon.com/s3/).

Cloud Crooner will run a Sprockets instance and configure helpers for your views. Create a rake task to call the sync method to compile your assets and upload them to the cloud. The helpers will make sure you're pointing to the S3 assets in prod. Your assets will have appended to their names an MD5 hash of their contents which updates when your assets change, ensuring that your users will always be served the freshest assets without needing to worry about expiring caches. 

## Installation

Add this line to your application's Gemfile:

    gem 'cloud_crooner'

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install cloud_crooner

## Configuration

Cloud Crooner has many configuration options which can be set in a configure block: 

    CloudCrooner.configure do |config|
      config.prefix = '/assets'
    end

`remote_enabled`  - true by default. When disabled, your assets will be served from your public folder instead of from S3. Only works in production. _Be aware that attempting to test this on your machine using rackup or thin will not work_. Rack does not serve files from `/public`. If you want to see static assets in action without messing with Rack internals, you must run [shotgun](https://github.com/rtomayko/shotgun) or something like it.

`public_folder` - the public folder of your application. By default set to `/public`. If you are using a different public folder, you must set it here as well as in your application.

`prefix` - the path from root where you keep your assets. By default it is `/assets`. Your compiled assets will be placed in `public_folder/prefix.` It will also be the pseudo-folder on S3 where your assets will be stored, so the paths will look something like `http://bucket-name.s3.amazonaws.com/prefix/filename`.

`sprockets` - by default, this will be your Sprockets environment and it will load paths the config option `asset_paths`. 

`asset_paths` - the [load paths](https://github.com/sstephenson/sprockets#the-load-path) for your Sprockets instance. By default it will add the `prefix` directory. 

`manifest` - the Sprockets manifest. By default, it will be created in `public_folder/prefix`. The manifest's location is also the folder where assets will be compiled to.

`assets_to_compile` - an array of the assets you would like compiled, given by their [logical Sprockets paths](https://github.com/sstephenson/sprockets#logical-paths). If Sprockets knows how to gzip your assets (it can do css and js by default), it will also gzip them. 

`backups_to_keep` - the number of compiled asset backups to keep. Default is 2. When running the sync task, if an asset's content has changed, it will be recompiled. If there are already more than the set number of backups present, the oldest asset will be deleted locally, removed from the manifest, and deleted remotely.

`bucket_name` - the name of your AWS S3 bucket. [See below for details.](#hooking_up )

`region` - the region of your AWS S3 bucket.  [See below for details.](#hooking_up )
 
`aws_access_id_key` - aws credentials. [See below for details.](#hooking_up )

`aws_secret_access_key` - aws credentials. [See below for details.](#hooking_up )

### No Configuration

If you're keen to run everything on defaults, you will still need to run one command in order to get the helpers working: 

    CloudCrooner.configure_sprockets_helpers

Normally this is called at the end of the configure method.

### <a id="hooking_up"></a>Hooking up with your Amazon S3 Account

After you have created an S3 account, [you will will be provided with an "access key id" and a "secret access key"](https://console.aws.amazon.com/iam/home?#security_credential). You will also need your bucket name and the bucket's region. One of the ways to find the region is by going to the [S3 console](https://console.aws.amazon.com/s3/) and checking the end of the URL: it will look something like us-west-1. Cloud Crooner will look for your AWS credentials in your ENV by default. _Do not put your credentials anywhere they can be checked into source control._ I would suggest loading them into the env with your bash login scripts. The env keys that will be checked by default are:

    ENV["AWS_SECRET_ACCESS_KEY"]  # the secret access key given by Amazon
    ENV["AWS_ACCESS_KEY_ID"]      # access key id given by Amazon 
    ENV["AWS_BUCKET_NAME"]        # the name of your bucket 
    ENV["AWS_REGION"]             # the region of your bucket

You may also set these in the Cloud Crooner config block, but please do not directly set the two Amazon credentials here.

    CloudCrooner.configure do |config|
      config.aws_secret_access_key = ENV["MY_AWS_SECRET"] 
      config.aws_access_key_id = ENV["MY_ACCESS_KEY"]
      config.bucket_name = "super-cool-bucket"
      config.aws_region = "eu-west-1"
    end

## Setting Up Your App:

I have thrown together a very simple application as an example. 

In a file of your choosing (in this case `/config/cloud_crooner_config.rb`) run the configuration block with your desired settings. 

    require 'cloud_crooner'

    CloudCrooner.configure do |config|
      config.backups_to_keep = 1
      config.asset_paths = %w( assets/stylesheets ) # assuming this is where I put my sass files
      config.assets_to_compile %w( main.css )  # assuming this is the file I want to compile
    end

In config.ru, require this file, and set up the following:

    require './config/cloud_crooner_config.rb' # your Cloud Crooner config file
    require './app.rb' # your app file

    map '/' + CloudCrooner.prefix do
      run CloudCrooner.sprockets
    end

    map '/' do
      run App # your application class name
    end

To compile and upload the assets, in your rakefile:

    require './config/cloud_crooner_config.rb'
    
    namespace :assets do
      desc 'compile and sync assets' do
      task :sync do
        CloudCrooner.sync
      end
    end

Now on the command line, run `rake assets:sync` and the following will happen:

1. new or changed assets will be compiled into `public/assets` 
2. assets will be uploaded to the S3 bucket, which is set in ENV elsewhere. If an asset has a gzipped file associated with it and the gzip is smaller than the original file, the gzip will be uploaded in its place
3. manifest will be updated
4. old backups locally and remotely will be deleted

Running your app in development mode will serve uncompiled assets locally (from `/assets`), and running your app in production mode will serve your compiled assets from S3. If you have `remote_assets` set to `false` and are in production mode, your compiled assets will be served from `public/assets`.

If you want to precompile and upload your assets every time you spin up your app, you can put the configure block directly into config.ru and after config run CloudCrooner.sync.

## Contributing

If there's a feature you'd like to see, when you create an issue, please supply a valid use case. If you'd like to fix a bug or add a feature yourself, please update relevant tests before submitting a pull request. 
