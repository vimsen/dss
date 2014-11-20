require 'uri'
require 'open-uri'
require 'json'
require 'yaml'

module FetchAsynch
  class DownloadDayAhead
    def initialize prosumers, dayahead, date
      u = YAML.load_file('config/config.yml')[Rails.env]["intellen_host"]
      uri = URI.parse(u+'/getdayahead');
      params = {:prosumers => prosumers,
                :date => date}
      uri.query = URI.encode_www_form(params);
      puts uri, prosumers, date
      result = JSON.parse(uri.open.read)
      datareceived result, dayahead
      ActiveRecord::Base.connection.close
    end
    
    private
      def datareceived data, dayahead
        data.each do |d|
          unless Prosumer.where(intelen_id: d["prosumer_id"].to_i).first.nil?
            d["points"].each do |p|
              dahh = DayAheadHour.new(
                :day_ahead => dayahead,
                :time => p["time"],
                :production => p["production"],
                :consumption => p["consumption"]
              )
              dahh.save
            end
          end
        end
      end
  end
end
