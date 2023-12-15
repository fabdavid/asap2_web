class ExpEntryIdentifier < ApplicationRecord

  belongs_to :exp_entry
  belongs_to :identifier_type

end
