class Organism < ApplicationRecord

  has_many :genes
  has_many :gene_sets

end
