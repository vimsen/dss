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
      result = JSON.parse(uri.open.read)
      datareceived result, dayahead
    end
    
    private
      def datareceived data, dayahead
        data.each do |d|
          unless Prosumer.find(d["prosumer_id"].to_i).nil?
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
