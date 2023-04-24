class IdentifierType < ApplicationRecord

  has_many :exp_entries
  has_many :sample_identifiers
  has_many :exp_entry_identifiers

end
