class GeneSet < ApplicationRecord

belongs_to :project
has_many :gene_set_names

end
