require 'rest-client'
require 'yaml'
require 'fetch_asynch/download_and_publish'

class BidDayAheadJob < ActiveJob::Base
  queue_as :default

  def perform(*args)

    Rails.logger.debug "Arguments:  #{ENV["download"]}"
    Rails.logger.debug "Downloading data:"

    if ENV["download"] != "false"
      FetchAsynch::DownloadAndPublish.new(Prosumer.all, 2, DateTime.now - 2.days, DateTime.now + 48.hours, nil, true)
    end



    Rails.logger.debug "Downloaded data"
    config = YAML.load(ERB.new(File.read("#{Rails.root}/config/vimsen_hosts.yml")).result)
    
    # YAML.load_file('config/vimsen_hosts.yml')

    user = config[Rails.env]["market_operator"]["user"]
    token = config[Rails.env]["market_operator"]["token"]
    base_uri = config[Rails.env]["market_operator"]["host"]

    rest_resource = RestClient::Resource.new(base_uri)

    markets = JSON.parse rest_resource['markets'].get params: {user_email: user, user_token: token, format: :json}

    Rails.logger.debug "Downloaded markets"

    day_ahead_market = (markets.find do |m|
      m["name"] == "Day Ahead"
    end)

    Rails.logger.debug "found day ahead market"
    newbid = {
        market_id: day_ahead_market["id"],
        date: Date.tomorrow.to_s,
        bid_items_attributes: day_ahead_market["blocks"].map do |b|
          volume = DataPoint.where(interval_id: 2, f_timestamp: Date.tomorrow.beginning_of_day + b["starting"].seconds + 1.hour)
                       .select('sum(COALESCE(f_consumption,0) - COALESCE(f_production,0)) as f_prosumption')
                       .group(:f_timestamp).map{|dp| dp.f_prosumption}.first || 0
          {
              block_id: b["id"].to_i,
              volume: volume,
              price: 50.0
          }
        end.reject do |b|
          b[:volume] == 0
        end
    }
    Rails.logger.debug "created bid"
    request_object = {
        bid: newbid, user_email: user, user_token: token
    }
    Rails.logger.debug "created request object"
    Rails.logger.debug "#{day_ahead_market["blocks"]}, #{request_object.to_json}"

    result = rest_resource['bids'].post(request_object.to_json, :content_type => :json, :accept => :json)
    Rails.logger.debug "The result is #{result}"

    json_response = JSON.parse result

    if json_response["status"] == "submitted"
      Bid.create date: json_response["date"],
                 mo_id: json_response["id"],
                 status: json_response["status"]
    end

   # bid = JSON.parse(rest_resource['bids'].post(request_object.to_json, :content_type => :json, :accept => :json))
   # Rails.logger.debug "Posted new bid"

   # Rails.logger.debug "The number of data points is #{DataPoint.count}, user is #{user}. Bid is #{bid}."
    # Do something later
  end
end
