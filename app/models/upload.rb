class Upload < ActiveRecord::Base
  # Variables
  UPLOAD_STATUSES = %w(new uploading uploaded)

  # Validations
  validates :name, presence: true
  validates :status, inclusion: { in: UPLOAD_STATUSES } 

  # Paperclip
  has_attached_file :upload, url: "/storage/:class/:id/:basename.:extension"
  validates_attachment :upload, content_type: { content_type: ['application/zip', 'application/pdf', 'text/plain'] }

  def to_jq_upload(error=nil)
    {
      files: [
        {
          name: read_attribute(:upload_file_name),
          size: read_attribute(:upload_file_size),
          url: upload.url(:original),
          delete_url: Rails.application.routes.url_helpers.upload_path(self),
          delete_type: "DELETE" 
        }
      ]
    }
  end

  def upload_done?
    status.in? %w(uploaded) 
  end
end
