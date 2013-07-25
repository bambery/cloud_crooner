require 'fog'
require 'rack/mime'

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
      @local_assets ||= self.config.manifest.assets.values.map {|f| File.join(self.config.prefix, f)} 
    end

    def upload_files
      #upload all files in manifest
    end

    def log(msg)
      CloudCrooner.log(msg)
    end

    def upload_file(f)
      full_file_path = File.join(self.config.local_assets_dir, f)
      one_year = 31557600
      mime = Rack::Mime.mime_type(File.extname(f)) 
      file = {
        :key => File.join(self.config.prefix, f),
        :public => true,
        :content_type => mime,
        :cache_control => "public, max-age=#{one_year}",
        :expires => CGI.rfc1123_date(Time.now + one_year) 
      }

      gzipped = "#{full_file_path}.gz" 

      # if a gzipped version of the file exists and is a smaller file size than the original, upload that in place of the uncompressed file
      if File.exists?(gzipped)
        original_size = File.size(full_file_path)
        gzipped_size = File.size(gzipped)

        if gzipped_size < original_size
          file.merge!({
            :body => File.open(gzipped),
            :content_encoding => 'gzip'
          })
          log "Uploading #{gzipped} in place of #{f}"
        else
          file.merge!({
            :body => File.open(full_file_path)
          })
          log "Gzip exists but has larger file size, uploading #{f}"
        end
      else
        file.merge!({
          :body => File.open(full_file_path)
        })
        log "Uploading #{f}"
      end
        # put in reduced redundancy option here later if desired

        p "MY OPTIONS! #{file}"
        file =  bucket.files.create( file )
    end

    def remote_files
      files = []
      bucket.files.each { |f| files << f.key }
      return files
    end
  end
end
