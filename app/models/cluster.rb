class Cluster < ActiveRecord::Base
  has_many :prosumers
  resourcify
  
  include FindGaps
  
  def getNotMembers
    return Prosumer.where("cluster_id IS ? OR cluster_id != ?", nil, self.id)
  end
  
  def request_cached(interval, startdate, enddate, channel, forecasts: "edms")
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

      # if (missing_data)
        FetchAsynch::DownloadAndPublish.new prosumers: prosumerlist,
                                            interval: interval,
                                            startdate: startdate,
                                            enddate: enddate,
                                            channel: channel,
                                            async: false,
                                            forecasts: forecasts,
                                            only_missing: true
      # end

      return {
          data_points: result,
          fms: self.prosumers
                   .map{|p| p.new_forecast(interval, startdate, enddate)}
                   .reduce(:merge)&.merge(self.new_forecast(interval, startdate, enddate))
      }
    end
  end
  
  def get_icon_index
    Cluster.all.index(self)
  end

  def new_forecast(interval, startdate, enddate)
    fms = Forecast.day_ahead.where(prosumer: self.prosumers, timestamp: startdate..enddate, interval: interval)
        .group(:timestamp).select('timestamp, sum(production) as s_production, sum(consumption) as s_consumption, sum(storage) as s_storage')
        .order(timestamp: :asc)
    {
        "Aggregate prosumption forecast": fms.map{|t| [t.timestamp.to_i , [t.timestamp.to_i * 1000, t.s_consumption - t.s_production]] }.to_h,
        "Aggregate production forecast": fms.map{|t| [t.timestamp.to_i , [t.timestamp.to_i * 1000, t.s_production]] }.to_h,
        "Aggregate consumption forecast": fms.map{|t| [t.timestamp.to_i, [t.timestamp.to_i * 1000, t.s_consumption]] }.to_h,
        "Aggregate storage forecast": fms.map{|t| [t.timestamp.to_i , [t.timestamp.to_i * 1000, t.s_storage]] }.to_h
    }
  end

end
