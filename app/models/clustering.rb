class Clustering < ActiveRecord::Base
  has_many :temp_clusters, dependent: :destroy
  accepts_nested_attributes_for :temp_clusters, :allow_destroy => true

  def get_icon_index(prosumer)
    self.temp_clusters.index(self.temp_clusters.select do |tc|
                               tc.prosumers.include? prosumer
                             end.first) || "N"
  end
end
