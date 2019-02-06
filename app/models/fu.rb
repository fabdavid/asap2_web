class Fu < ActiveRecord::Base

  belongs_to :project, :optional => true

  # Variables
  FU_STATUSES = %w(new uploading uploaded)

  # Validations
  #  validates :name, presence: true
  validates :status, inclusion: { in: FU_STATUSES } 

  # Paperclip
  has_attached_file :upload, url: "/data/:class/:id/:filename"
  do_not_validate_attachment_file_type  :upload #, content_type: { content_type: ['text/plain'] }
#  validates_attachment :upload, content_type: { content_type: ['application/zip', 'application/pdf', 'text/plain'] }
  
  def broadcast
    FuBroadcastJob.perform_later self
  end

  NewDownload = Struct.new(:fu, :url) do
    def perform
      fu.download url
    end

    def error(job, exception)
    end
  end

#  def start_download
#    Delayed::Job.enqueue NewDownload.new(self), :queue => 'fast'
#  end
  
  def to_jq_upload(error=nil)
    {
      files: [
        {
          name: read_attribute(:upload_file_name),
          size: read_attribute(:upload_file_size),
          url: upload.url(:original),
          delete_url: Rails.application.routes.url_helpers.fu_path(self),
          delete_type: "DELETE" 
        }
      ]
    }
  end

  def upload_done?
    status.in? %w(uploaded) 
  end

  def download url

    require 'open-uri'

    enc_url = URI.escape url
    
    filename = 'input_file'
    @valid_url = 0
    if !env_url =~ /\A#{URI::regexp(['http', 'https', 'ftp'])}\z/
      enc_url = "http://" + enc_url
    end
    if enc_url =~ /\A#{URI::regexp(['http', 'https', 'ftp'])}\z/
      @valid_url = 1
      if m = enc_url.match(/([^\/]+)$/)
        filename = m[1]
      end
      ## update url and filename                                                                                                                        
      self.update_attributes({
                              :upload_file_name => filename,
                              :url => enc_url
                            })

      upload_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'fus' + self.id.to_s
      Dir.mkdir upload_dir if !File.exist? upload_dir
      filepath = upload_dir + self.upload_file_name
      cmd = "wget -O #{filepath} #{enc_url} 2> log/wget.err 1> log/wget.log"
      logger.debug(cmd)
      
      #            IO.copy_stream(open(url), filepath)                                                                                                     
      # Basic.safe_download(url, filepath)      
      `#{cmd}`
      # logger.debug("bla")
      if File.exist? filepath
        self.update_attributes({:upload_file_size => File.size(filepath), :upload_file_name => filename})
      end

    end

    self.broadcast
    
  end



end
