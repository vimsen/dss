class Clustering < ActiveRecord::Base
  has_many :temp_clusters, dependent: :destroy
  accepts_nested_attributes_for :temp_clusters, :allow_destroy => true
end
