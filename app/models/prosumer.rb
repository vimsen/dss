require 'fetch_asynch/download_and_publish'

class Prosumer < ActiveRecord::Base
  has_many :measurements, dependent: :destroy
  has_many :data_points, dependent: :destroy
  has_many :day_aheads, dependent: :destroy

  belongs_to :cluster
  resourcify

  has_and_belongs_to_many :users
  
  def request_cached(interval, startdate, enddate)
    result = []
    puts "#{interval}, #{startdate}, #{enddate}"
    self.data_points.where(timestamp: startdate..enddate, interval: interval).order(timestamp: :asc).each do |dp|
      result.push( dp.clientFormat )  
    end
    FetchAsynch::DownloadAndPublish.new(self.id, interval, startdate, enddate, "prosumer.#{self.id}") 
   
    return result      
  end
end
