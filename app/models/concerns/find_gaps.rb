module FindGaps
  extend ActiveSupport::Concern
  
  def find_gaps datapoints, startdate, enddate, interval_secs
    
    if datapoints.count > 0
      cached_startdate = datapoints.first.timestamp
      cached_enddate = datapoints.last.timestamp
      
      i_gaps = (cached_enddate.to_i - cached_startdate.to_i) / interval_secs  
      
      s_gap = cached_startdate.to_i - startdate.to_i
      e_gap = enddate.to_i - cached_enddate.to_i
       
      points = datapoints.count
    
    end
    
    datapoints.count == 0 || points < i_gaps + 1 || s_gap > interval_secs || e_gap > interval_secs
     
  end
  
end