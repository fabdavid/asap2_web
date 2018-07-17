class Selection < ApplicationRecord

  belongs_to :project
  belongs_to :cluster


  def content
  
    project = self.project
    filename = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key + 'selections' + (self.id + ".txt")  
    return File.read(filename).split("\n")
    
  end

end
