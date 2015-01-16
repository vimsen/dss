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
  
  include FindGaps
  
  def request_cached(interval, startdate, enddate)
    
    dps = self.data_points.where(timestamp: startdate..enddate, interval: interval).order(timestamp: :asc)
    
    result = dps.map { |dp| dp.clientFormat }
    
    
    if find_gaps dps, startdate, enddate, Interval.find(interval).duration
      FetchAsynch::DownloadAndPublish.new(self.intelen_id, interval, startdate, enddate, "prosumer.#{self.id}")
    end 
    
    return result      
  end
  
  def self.with_locations
    Prosumer.where("location_x IS NOT NULL and location_y IS NOT NULL") 
  end

  def self.with_positive_dr
    Prosumer.select { |p| p.max_dr && p.max_dr > 0 }
  end

  def self.with_dr
    Prosumer.select { |p| p.max_dr }
  end

  def max_dr
    self.data_points.empty? ? nil : self.data_points.max { |dp| dp.dr }.dr
  end
  
end
