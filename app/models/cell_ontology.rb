class CellOntology < ApplicationRecord

  has_and_belongs_to_many :organisms
  has_many :cell_ontology_terms

  searchable do
    text :tax_id do
      tax_ids.split(",")
    end
    text :name
    text :tag
  end

end
