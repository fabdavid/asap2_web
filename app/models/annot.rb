class Annot < ApplicationRecord

  belongs_to :project
  belongs_to :step
  belongs_to :run
  belongs_to :user
  belongs_to :data_type, :optional => true

end
