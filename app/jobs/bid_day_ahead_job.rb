require 'rest_client'
require 'yaml'
require 'fetch_asynch/download_and_publish'

class BidDayAheadJob < ActiveJob::Base
  queue_as :default

  def perform(*args)

    FetchAsynch::DownloadAndPublish.new(Prosumer.all, 2, Date.yesterday, Time.now, nil, true)

    config = YAML.load_file('config/config.yml')

    user = config[Rails.env]["market_operator"]["user"]
    token = config[Rails.env]["market_operator"]["token"]
    base_uri = config[Rails.env]["market_operator"]["host"]

    rest_resource = RestClient::Resource.new(base_uri, verify_ssl: OpenSSL::SSL::VERIFY_NONE)

    markets = JSON.parse rest_resource['markets'].get params: {user_email: user, user_token: token, format: :json}

    day_ahead_market = (markets.find do |m|
      m["name"] == "Day Ahead"
    end)

    newbid = {
        market_id: day_ahead_market["id"],
        date: Date.tomorrow.to_s,
        bid_items_attributes: day_ahead_market["blocks"].map do |b|
          {
              block_id: b["id"].to_i,
              volume: rand(10.0...200.0),
              price: rand(1.0...20.0)
          }
        end
    }
    request_object = {
        bid: newbid, user_email: user, user_token: token
    }
    # puts day_ahead_market["blocks"], request_object.to_json

    bid = JSON.parse rest_resource['bids'].post request_object.to_json, :content_type => :json, :accept => :json

    puts "The number of data points is #{DataPoint.count}, user is #{user}. Bid is #{bid}."
    # Do something later
  end
end
