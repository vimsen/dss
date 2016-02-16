require 'rest-client'
require 'yaml'
require 'fetch_asynch/download_and_publish'

class BidDayAheadJob < ActiveJob::Base
  queue_as :default

  def perform(*args)

    puts "Arguments:  #{ENV["download"]}"
    puts "Downloading data:"

    if ENV["download"] != "false"
      FetchAsynch::DownloadAndPublish.new(Prosumer.all, 2, DateTime.now - 2.weeks, DateTime.now + 48.hours, nil, true, true)
    end



    puts "Downloaded data"
    config = YAML.load_file('config/config.yml')

    user = config[Rails.env]["market_operator"]["user"]
    token = config[Rails.env]["market_operator"]["token"]
    base_uri = config[Rails.env]["market_operator"]["host"]

    rest_resource = RestClient::Resource.new(base_uri)

    markets = JSON.parse rest_resource['markets'].get params: {user_email: user, user_token: token, format: :json}

    puts "Downloaded markets"

    day_ahead_market = (markets.find do |m|
      m["name"] == "Day Ahead"
    end)

    puts "found day ahead market"
    newbid = {
        market_id: day_ahead_market["id"],
        date: Date.tomorrow.to_s,
        bid_items_attributes: day_ahead_market["blocks"].map do |b|
          {
              block_id: b["id"].to_i,
              volume: DataPoint.where(f_timestamp: Date.tomorrow.to_datetime + b["starting"].seconds).map{|dp| (dp.f_consumption - dp.f_production)}.sum,
              price: rand(1.0...20.0)
          }
        end.reject do |b|
          b[:volume] == 0
        end
    }
    puts "created bid"
    request_object = {
        bid: newbid, user_email: user, user_token: token
    }
    puts "created request object"
    puts day_ahead_market["blocks"], request_object.to_json

    result = rest_resource['bids'].post(request_object.to_json, :content_type => :json, :accept => :json)
    puts "The result is #{result}"

    json_response = JSON.parse result

    if json_response["status"] == "submitted"
      Bid.create date: json_response["date"],
                 mo_id: json_response["id"],
                 status: json_response["status"]
    end

   # bid = JSON.parse(rest_resource['bids'].post(request_object.to_json, :content_type => :json, :accept => :json))
   # puts "Posted new bid"

   # puts "The number of data points is #{DataPoint.count}, user is #{user}. Bid is #{bid}."
    # Do something later
  end
end
