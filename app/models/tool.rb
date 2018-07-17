class Tool < ApplicationRecord

belongs_to :tool_type
has_many :db_sets

end
