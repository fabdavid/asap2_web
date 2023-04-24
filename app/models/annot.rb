class Annot < ApplicationRecord

  belongs_to :project
  belongs_to :step
  belongs_to :run
  belongs_to :user
  belongs_to :data_type, :optional => true
  belongs_to :output_attr, :optional => true
  has_many :clas
  has_many :annot_cell_sets
end
