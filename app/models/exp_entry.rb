class ExpEntry < ApplicationRecord

  has_and_belongs_to_many :projects
  has_and_belongs_to_many :sample_identifiers
  belongs_to :identifier_type

end
