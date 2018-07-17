class DimReduction < ApplicationRecord

has_many :project_dim_reductions
belongs_to :speed

end
