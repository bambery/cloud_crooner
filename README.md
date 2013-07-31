# CloudCrooner

In Sinatra, manage your assets with [Sprockets](https://github.com/sstephenson/sprockets) and sync them with [Amazon S3](http://aws.amazon.com/s3/).

Why Sprockets? Simply put, the manifest combined with the ability to compile digest assets is indispensible to ensure you're always serving the freshest assets to your users. 

## Installation

Add this line to your application's Gemfile:

    gem 'cloud_crooner'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cloud_crooner

## Usage

### How to use Sprockets with Sinatra

#### Basic Sprockets Setup

In your config.ru:
    
    require '/app.rb'

    map App.assets_prefix do 
      run App.sprockets
    end

    map "/" do
      run App
    end

In app.rb in your configure block, create an instance of Sprockets. Place your assets (stylesheets, javascripts, and images are the most common, but it can be any file) in a subdirectory from root and set it in your configure block:
    
    set :sprockets, Sprockets::Environment.new(root) { | env | env.logger = Logger.new($stdout) }
    set :assets_prefix, '/assets'

What this does: Sprockets will grab any route under www.yourapp.com/assets and search its (Sprockets's) load path for the file. So let's tell it to add some stylesheets to the load path:

    configure :development
      sprockets.append_path File.join(root, assets_prefix, 'stylesheets')
    end

In my app, I have the path root/assets/stylesheets/ under which I keep my sass files. I have the [ sprockets-sass ](https://github.com/petebrowne/sprockets-sass) and [ sass ](https://github.com/nex3/sass)  gems to help Sprockets cope (sprockets-sass still necessary as of 06/30/13 for functional Sinatra @imports, email me if this changes). When a request comes for www.myapp.com/assets/main.css, Sprockets will hijack it when it hits '/assets', which we instructed it to do in config.ru. It will then search its load path, which right now consists only of root/assets/stylesheets. It will find main.scss at the path root/assets/stylesheets/main.scss, compile it, store it in some in-memory cache (in this instance, the default .sass-cache/ folder) and serve it back to the browser. It will appear in the browser as though the file is being served from www.myapp.com/assets/main.css.  If you wanted to instead serve the css from www.myapp.com/assets/stylesheets/main.css:

    sprockets.append_path File.join(root, assets_prefix)

Sprockets adds any and all subdirectories of paths added to the load path, but you must reference them in relation to the Sprockets load path.

Any custom options you would like to add to the assets processor of your choice can be done in the config block. For example, I want to compress my css files to remove whitespace:

    Sprockets::Sass.options[:style] = :compressed

But who wants to compile sass in prod? Gross. Let's get this set up to serve precompiled assets from S3. 

#### Compiling Static Assets

Sprocket's manifest is a json file which is created and updated while compiling your assets, which we will do in a rake task. It keeps track of details about your assets, and most importantly it keeps track of the most recent compiled version of your assets. It does this by attaching an MD5 hash of the contents of your file to the compiled filename. It will not trigger a recompile if the asset's content is unchanged but the mtime updates, making this ideal for use on Heroku which updates the mtime on every file after every push. 

We are going to put compiled assets in '/public/assets'. The manifest will by default be created in the same folder. In your configure block:
    
    set :manfest, Sprockets::Manifest.new(sprockets, File.join(public_folder, assets_prefix)
    set :digest_assets, true

If you do not want to host static assets on S3 and would prefer to serve them locally in prod, add this:

    configure :production do
      sprockets.append_path File.join(root, public_folder, assets_prefix)
    end

_Be aware that attempting to test this on your machine using rackup or thin will not work_. Rack does not serve files from public. If you want to see static assets in action without messing with Rack internals, you must run [shotgun](https://github.com/rtomayko/shotgun) or something like it.

At this point, I recommend using the [sprockets-helpers]( https://github.com/petebrowne/sprockets-helpers ) gem to dynamically generate links to your assets depending on your environment, so we can point to raw /assets in dev and compiled /your-aws-bucket in prod. It uses the manifest to generate a link to the most recent digest, meaning you never have to expire your assets in any cache, anywhere, ever. 

    register Sinatra::Sprockets::Helpers

Sprockets-helpers will grab your Sprockets settings to configure itself, but you need to run this block:

    configure_sprockets_helpers do |helpers|
      helpers.manifest = settings.manifest
    end

So let's actually create some static assets. Sprockets comes with a rake task macro which we will utilize. Create a Rakefile and put this in it:

    require './app' # your app file
    require 'sprockets'
    require 'rake/sprocketstask'

    Rake::SprocketsTask.new do |t|
      t.environment = App.sprockets
      t.manifest = App.manifest
      t.assets = 'main.css'  
    end

t.assets is an array of the assets you want compiled. You should reference the assets from their sprockets's load paths.

You now have three rake tasks at your disposal for dealing with assets:

+ `rake assets`: This will compile your assets and output them in `app_root/public_folder/assets_prefix`. It will also:
  1. create the manifest if it does not exist
  2. recompile assets that have changed with a new digest
  3. update the manifest to point an asset to its most recent digest
  4. update the manifest with new assets

It will not remove old assets from the manifest. It will also not honor the number of backups you have requested for an asset.

+ `rake clean_assets`: This will
  1. remove from the manifest any additional backups. If you requested to keep 2 and you now have 3, the oldest digest path will be removed from the manifest
  2. remove from the file system any additional backups. If you requested 2 and now have 3, Sprockets will delete from the local file system the oldest compiled digest file.
+ `rake clobber_assets`: This will delete the compiled assets folder and all of its contents.

Exciting! But if you are using CloudCrooner, you won't need to directly call any of these rake tasks, but knowledge is power. 

#### Caveats

This is not a full on guide to Sprockets (if such a thing exists, hook me up), but it should get you started.

One thing to note: Specifically for Sass files, do not use the Sprockets directives - use @include. See here for more details:

[Structure Your Sass Files with @import](http://pivotallabs.com/structure-your-sass-files-with-import/)

### Hooking up with your Amazon S3 Account

After you have created an S3 account, [you will will be provided with an "access key id" and a "secret access key"](https://portal.aws.amazon.com/gp/aws/securityCredentials). You will also need your bucket name and the bucket's region. The region can be found by going to the s3 console and checking the end of the URL: it will look something like us-west-1. Cloud Crooner will look for your AWS credentials in your ENV by default. _Do not put your credentials anywhere they can be checked into source control._ I would suggest loading them into the env in with your bash login scripts. The env keys that will be checked by default are:

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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
