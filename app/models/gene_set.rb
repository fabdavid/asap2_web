class GeneSet < ApplicationRecord

belongs_to :project, :optional => true
has_many :gene_set_names
has_many :gene_set_items

end
