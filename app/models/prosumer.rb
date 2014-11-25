require 'fetch_asynch/download_and_publish'

class Prosumer < ActiveRecord::Base
  has_many :measurements, dependent: :destroy
  has_many :data_points, dependent: :destroy
  has_many :day_aheads, dependent: :destroy

  belongs_to :cluster
  belongs_to :building_type
  belongs_to :connection_type
  
  resourcify

  has_and_belongs_to_many :users

  has_many :energy_type_prosumers
  has_many :energy_types, :through => :energy_type_prosumers

  accepts_nested_attributes_for :energy_type_prosumers,
    :allow_destroy => true

  validates :intelen_id, uniqueness: true
  
  def request_cached(interval, startdate, enddate)
    
    dps = self.data_points.where(timestamp: startdate..enddate, interval: interval).order(timestamp: :asc)
    
    result = dps.map { |dp| dp.clientFormat }
    
    # Below calculations are for determininig if all needed points are in the db
    
    if dps.count > 0
      int_secs = Interval.find(interval).duration
      
      cached_startdate = dps.first.timestamp
      cached_enddate = dps.last.timestamp
      
      i_gaps = (cached_enddate.to_i - cached_startdate.to_i) / int_secs  
      
      s_gap = cached_startdate.to_i - startdate.to_i
      e_gap = enddate.to_i - cached_enddate.to_i
      
      points = dps.count    
      
      puts "-------- #{points} #{i_gaps} #{s_gap} #{int_secs} #{e_gap}"
      
    end 
    
    if dps.count == 0 || points < i_gaps + 1 || s_gap > int_secs || e_gap > int_secs 
      FetchAsynch::DownloadAndPublish.new(self.intelen_id, interval, startdate, enddate, "prosumer.#{self.id}")
    end 
   
    return result      
  end
end
