class Cluster < ActiveRecord::Base
  has_many :prosumers
  resourcify
  
  def getNotMembers
    return Prosumer.where("cluster_id IS ? OR cluster_id != ?", nil, self.id)
  end
  
  def request_cached(interval, startdate, enddate)
    result = []
    puts "#{interval}, #{startdate}, #{enddate}"
    self.prosumers.each do |p| 
      p.data_points.where(timestamp: startdate..enddate, interval: interval).order(timestamp: :asc).each do |dp|
        result.push( dp.clientFormat )  
      end
    end  
    
    prosumerlist = self.prosumers.map { |d| d.id }.join(",")
    
    puts "prosumerlist: ", prosumerlist
    
    FetchAsynch::DownloadAndPublish.new(prosumerlist, interval, startdate, enddate, "cluster.#{self.id}") 
   
    return result      
  end

end
