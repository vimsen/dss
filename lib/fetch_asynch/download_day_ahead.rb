require 'uri'
require 'open-uri'
require 'json'
require 'yaml'

module FetchAsynch
  class DownloadDayAhead
    def initialize prosumers, dayahead, date
      u = YAML.load_file('config/vimsen_hosts.yml')[Rails.env]["edms_host"]
      uri = URI.parse(u+'/getdayahead');
      params = {:prosumers => prosumers,
                :date => date}
      uri.query = URI.encode_www_form(params);
      Rails.logger.debug "#{uri}, #{prosumers}, #{date}"
      ActiveRecord::Base.connection.close
      result = JSON.parse(uri.open.read)
      datareceived result, dayahead
      ActiveRecord::Base.connection.close
    end
    
    private
      def datareceived data, dayahead
        data.each do |d|
          unless Prosumer.where(edms_id: d["prosumer_id"].to_i).first.nil?
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
          ActiveRecord::Base.connection.close
        end
      end
  end
end
