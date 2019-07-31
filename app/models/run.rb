class Run < ApplicationRecord

  belongs_to :project
  belongs_to :step
  belongs_to :status
  belongs_to :std_method, :optional => true
  belongs_to :req, :optional => true
  belongs_to :user
  belongs_to :job, :optional => true
  #  belongs_to :active_run, :optional => true
  has_many :annots
  has_many :fos
  has_one :active_run
end
