class Step < ApplicationRecord

  has_many :std_methods
  has_many :project_steps
end
