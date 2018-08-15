class ProjectStep < ApplicationRecord

  belongs_to :project
  belongs_to :step
  belongs_to :status, :optional => true
  belongs_to :job, :optional => true

end
