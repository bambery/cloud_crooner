require 'fog'
require 'rack/mime'

module CloudCrooner
  class Storage

    def initialize
      @bucket_name = CloudCrooner.bucket_name 
      @prefix =      CloudCrooner.prefix 
      @fog_options = CloudCrooner.fog_options 
      @manifest =    CloudCrooner.manifest 
    end

    def connection
      @connection ||= Fog::Storage.new(@fog_options)
    end

    def bucket
      @bucket ||= connection.directories.get(@bucket_name, :prefix => @prefix)
    end

    def local_compiled_assets 
      # compiled assets prepended with prefix for comparison against remote
      @manifest.files.keys.map {|f| File.join(@prefix, f)} 
    end
    
    def exists_on_remote?(file)
      bucket.files.head(file)
    end

    def upload_files
      files_to_upload = local_compiled_assets.reject { |f| exists_on_remote?(f) }
      files_to_upload.each do |asset|
        upload_file(asset)
      end
    end

    def log(msg)
      CloudCrooner.log(msg)
    end

    def upload_file(f)
      # grabs the compiled asset from public_path
      full_file_path = File.join(File.dirname(@manifest.dir), f)
      one_year = 31557600
      mime = Rack::Mime.mime_type(File.extname(f)) 
      file = {
        :key => f,
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

        file =  bucket.files.create( file )
    end

    def remote_assets
      files = []
      bucket.files.each { |f| files << f.key }
      return files
    end

    def delete_remote_asset(f)
      log "Deleting #{f.key} from remote"
      f.destroy
    end

    def clean_remote
      to_delete = remote_assets - local_compiled_assets
      to_delete.each do |f|
        delete_remote_asset(bucket.files.get(f))
      end
    end
    
  end
end
