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

### Hooking up with your Amazon S3 Account

After you have created an S3 account, [you will will be provided with an "access key id" and a "secret access key"](https://portal.aws.amazon.com/gp/aws/securityCredentials). You will also need your bucket name and the bucket's region. One of the ways to fin the region is by going to the s3 console and checking the end of the URL: it will look something like us-west-1. Cloud Crooner will look for your AWS credentials in your ENV by default. _Do not put your credentials anywhere they can be checked into source control._ I would suggest loading them into the env in with your bash login scripts. The env keys that will be checked by default are:

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
