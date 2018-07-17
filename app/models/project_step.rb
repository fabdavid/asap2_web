class ProjectStep < ApplicationRecord

  belongs_to :project
  belongs_to :step
  belongs_to :status
  belongs_to :job

end
