class Cluster < ActiveRecord::Base
  has_many :prosumers
  resourcify
  
  include FindGaps
  
  def getNotMembers
    return Prosumer.where("cluster_id IS ? OR cluster_id != ?", nil, self.id)
  end
  
  def request_cached(interval, startdate, enddate, channel)
    result = []
    aggregate = {}
    count = {}
    missing_data = false

    prosumerlist = []

    ActiveRecord::Base.connection_pool.with_connection do
      self.prosumers.each do |p|
        dps = p.data_points.where(timestamp: startdate..enddate, interval: interval).order(timestamp: :asc)

        dps.each do |dp|
          result.push( dp.clientFormat )
          if aggregate[dp.timestamp].nil?
            aggregate[dp.timestamp] = DataPoint.new
            aggregate[dp.timestamp].init_zero dp.timestamp, -1, dp.interval, dp.f_timestamp
            count[dp.timestamp] = 0
          end
          count[dp.timestamp] += 1
          aggregate[dp.timestamp].add_data_doint dp
        end

        if find_gaps dps, startdate, enddate, Interval.find(interval).duration
          missing_data = true
        end

      end

      num = self.prosumers.count

      Rails.logger.debug "Checking aggregate:"
      aggregate.each do |key, value|
        # if count[key] == num
        res = value.clientFormat;
        res[:prosumer_name] = "Aggregate"
        result.push(res)
        # end
      end


      prosumerlist = self.prosumers
    end

    if (missing_data)
      FetchAsynch::DownloadAndPublish.new prosumers: prosumerlist,
                                          interval: interval,
                                          startdate: startdate,
                                          enddate: enddate,
                                          channel: channel,
                                          async: false,
                                          forecasts: false
    end   
   
    return result      
  end
  
  def get_icon_index
    Cluster.all.index(self)
  end

end
