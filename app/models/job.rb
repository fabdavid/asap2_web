class Job < ApplicationRecord

belongs_to :project
belongs_to :step
belongs_to :status
belongs_to :req, :optional => true

end
