class Cluster < ActiveRecord::Base
  has_many :prosumers
  
  def getNotMembers
    return Prosumer.where("cluster_id IS ? OR cluster_id != ?", nil, self.id)
  end
end
