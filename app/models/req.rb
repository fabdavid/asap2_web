class Req < ApplicationRecord

  belongs_to :step
  belongs_to :std_method
  has_many :runs
  belongs_to :user

end
