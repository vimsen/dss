class Clustering < ActiveRecord::Base
  has_many :temp_clusters, dependent: :destroy
end
