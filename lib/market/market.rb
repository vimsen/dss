module Market

  def optimal_cost(prosumers, startDate, endDate)
    DataPoint.where(prosumer: prosumers,interval: 2,f_timestamp: startDate .. endDate).group(:f_timestamp).sum(:f_consumption)  end

  class Market



  end
end