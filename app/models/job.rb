class Job < ApplicationRecord

belongs_to :project
belongs_to :step
belongs_to :status

end
