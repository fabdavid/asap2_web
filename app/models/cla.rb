class Cla < ApplicationRecord

  belongs_to :project
  belongs_to :annot
  belongs_to :orcid_user, :optional => true
  belongs_to :user, :optional => true
  belongs_to :cell_set, :optional => true
  has_many :cla_votes

end
