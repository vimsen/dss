class CheckBidStatusJob < ActiveJob::Base
  queue_as :default

  def perform(*args)
    Bid.submitted.each do |b|
      config = YAML.load_file('config/config.yml')

      user = config[Rails.env]["market_operator"]["user"]
      token = config[Rails.env]["market_operator"]["token"]
      base_uri = config[Rails.env]["market_operator"]["host"]

      rest_resource = RestClient::Resource.new(base_uri)
      response = rest_resource["bids/#{b.mo_id}.json"].get params: {user_email: user, user_token: token, format: :json}

      puts response
      json = JSON.parse response

      b.status = json["status"]

      if json["status"] == "accepted"
        json["sla_items"].each do |sla_item|
          b.sla_items.build(timestamp: DateTime.parse("#{json["date"]} #{sla_item["block"].split(/ /).last} +#{ActiveSupport::TimeZone['EET'].now.utc_offset/3600}"),
                            interval: Interval.find_by_duration(3600),
                            volume: sla_item["volume"],
                            price: sla_item["price"]
          )
        end
      end
      b.save
    end

  end
end
