require 'rest_client'
require 'yaml'

class BidDayAheadJob < ActiveJob::Base
  queue_as :default

  def perform(*args)

    config = YAML.load_file('config/config.yml')

    user = config[Rails.env]["market_operator"]["user"]
    token = config[Rails.env]["market_operator"]["token"]
    base_uri = config[Rails.env]["market_operator"]["host"]

    uri = "#{base_uri}/bids/"

    rest_resource = RestClient::Resource.new(uri, verify_ssl: OpenSSL::SSL::VERIFY_NONE)

    puts JSON.pretty_generate rest_resource.get

    puts "The number of data points is #{DataPoint.count}, user is #{user}."
    # Do something later
  end
end
