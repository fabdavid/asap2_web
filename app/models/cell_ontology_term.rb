class CellOntologyTerm < ApplicationRecord

  belongs_to :cell_ontology

  searchable do
    integer :id
    text :identifier
    text :tax_id do
      (tax_ids = cell_ontology.tax_ids) ? tax_ids.split(",") : []
    end

    text :alt_identifier do
      (alt_identifiers) ? alt_identifiers.split(",") : []
    end
    boolean :obsolete
    text :name
    text :description
    integer :cell_ontology_id
    boolean :original do
      t = (identifier) ? identifier.split(":") : ['']
      (t[0] == cell_ontology.tag) ? true : false
    end
    text :parent_term_id do
      (parent_term_ids) ? parent_term_ids.split(",") : []
    end
    text :lineage_term_id do
      (lineage) ? lineage.split(",") : []
    end
    text :node_term_id do
      (node_term_ids) ? node_term_ids.split(",") : []
    end

  end



end
