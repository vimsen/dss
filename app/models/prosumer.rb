require 'fetch_asynch/download_and_publish'


class Prosumer < ActiveRecord::Base
  
  has_many :data_points, dependent: :delete_all
  has_many :day_aheads, dependent: :destroy
  has_many :meters, dependent: :destroy

  belongs_to :cluster
  belongs_to :building_type
  belongs_to :connection_type
  
  resourcify

  has_and_belongs_to_many :users
  has_and_belongs_to_many :temp_clusters

  has_many :energy_type_prosumers
  has_many :energy_types, :through => :energy_type_prosumers

  accepts_nested_attributes_for :energy_type_prosumers,
    :allow_destroy => true

  validates :edms_id, uniqueness: true
  
  include FindGaps
  
  def request_cached(interval, startdate, enddate, channel)

    gaps = true
    result = []
    ActiveRecord::Base.connection_pool.with_connection do
      dps = self.data_points.where(timestamp: startdate..enddate, interval: interval).order(timestamp: :asc)
      result = dps.map { |dp| dp.clientFormat }
      gaps = find_gaps(dps, startdate, enddate, Interval.find(interval).duration)
    end
    
    # if gaps    # Download anyway, we may have an extra datapoint due to forecasts
    FetchAsynch::DownloadAndPublish.new([self], interval, startdate, enddate, channel)
    # end
    
    return result      
  end
  
  def self.with_locations
    Prosumer.where("location_x IS NOT NULL and location_y IS NOT NULL") 
  end

  def has_location
    ! (location_x.nil? || location_y.nil?)
  end

  def self.with_positive_dr
    Prosumer.select { |p| p.max_dr && p.max_dr > 0 }
  end

  def self.with_dr
    Prosumer.select { |p| p.max_dr }
  end

  def max_dr
    self.data_points.empty? ? nil : self.data_points.maximum(:dr)
  end
  
end
