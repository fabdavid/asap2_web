class OtProject < ApplicationRecord

belongs_to :project
belongs_to :cell_ontology_term
belongs_to :ontology_term_type

end
