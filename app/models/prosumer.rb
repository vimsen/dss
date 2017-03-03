require 'fetch_asynch/download_and_publish'


class Prosumer < ActiveRecord::Base
  
  has_many :data_points, dependent: :delete_all
  has_many :day_aheads, dependent: :destroy
  has_many :meters, dependent: :destroy
  has_many :forecasts, dependent: :destroy

  belongs_to :cluster
  belongs_to :building_type
  belongs_to :connection_type
  belongs_to :prosumer_category

  resourcify

  has_and_belongs_to_many :users
  has_and_belongs_to_many :temp_clusters

  has_many :energy_type_prosumers
  has_many :energy_types, :through => :energy_type_prosumers

  accepts_nested_attributes_for :energy_type_prosumers,
    :allow_destroy => true

  validates :edms_id, uniqueness: true
  
  include FindGaps

  scope :real_time, -> { joins(:prosumer_category).where("prosumer_categories.real_time": true) }
  scope :category, ->(cat) { where(prosumer_category: cat) if cat.present? }
  scope :with_locations, -> { where("location_x IS NOT NULL and location_y IS NOT NULL") }
  scope :with_positive_dr, ->(time_range) { select { |p| p.max_dr(time_range) && p.max_dr(time_range) > 0 } }
  scope :with_dr, ->(time_range) { select { |p| p.max_dr(time_range) } }

  def request_cached(interval, startdate, enddate, channel, forecasts: "edms")

    gaps = true
    result = []
    ActiveRecord::Base.connection_pool.with_connection do
      return {data_points: [], fms: []} if ((enddate - startdate)  * 24 * 60 * 60).to_f / Interval.find(interval).duration > 1000
      dps = self.data_points.where(timestamp: startdate..enddate, interval: interval).order(timestamp: :asc)
      result = {
          data_points: dps.map { |dp| dp.clientFormat },
          fms: new_forecast(interval, startdate, enddate)
      }
      # gaps = find_gaps(dps, startdate, enddate, Interval.find(interval).duration)
    end
    
    # if gaps    # Download anyway, we may have an extra datapoint due to forecasts
    FetchAsynch::DownloadAndPublish.new prosumers: [self],
                                        interval: interval,
                                        startdate: startdate,
                                        enddate: enddate,
                                        channel: channel,
                                        async: false,
                                        forecasts: forecasts
    # end
    
    return result      
  end

  def new_forecast(interval, startdate, enddate)
    fms = self.forecasts.day_ahead.where(timestamp: startdate..enddate, interval: interval).order(timestamp: :asc)
    fms.count > 0 ? {
        "#{name} prosumption forecast": fms.map{|t| [t.timestamp.to_i , [t.timestamp.to_i * 1000, t.consumption - t.production]] }.to_h,
        "#{name} production forecast": fms.map{|t| [t.timestamp.to_i , [t.timestamp.to_i * 1000, t.production]] }.to_h,
        "#{name} consumption forecast": fms.map{|t| [t.timestamp.to_i, [t.timestamp.to_i * 1000, t.consumption]] }.to_h,
        "#{name} storage forecast": fms.map{|t| [t.timestamp.to_i , [t.timestamp.to_i * 1000, t.storage]] }.to_h
    } : {}
  end

  def has_location
    ! (location_x.nil? || location_y.nil?)
  end

  def max_dr(time_range)
    self.data_points.where(timestamp: time_range).empty? ? nil : self.data_points.where(timestamp: time_range).maximum(:dr)
  end
  
end
