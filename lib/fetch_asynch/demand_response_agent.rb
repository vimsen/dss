module FetchAsynch
  class DemandResponseAgent
    def initialize
      config = YAML.load_file('config/config.yml')
      base_uri = config[Rails.env]["gdrms_host"]

      @rest_resource = RestClient::Resource.new(base_uri)

    end

    def dr_activation(demand_response_id)
      ActiveRecord::Base.connection_pool.with_connection do
        dr_obj = DemandResponse.find(demand_response_id)
        request_object = {
            start_time: dr_obj.starttime.to_s,
            interval: dr_obj.interval.duration,
            unit: "kW",
            target_reduction: dr_obj.dr_targets.order(timestamp: :asc).map{|t| t.volume},
            prosumers_primary: [1,4,7,10],
            prosumers_secondary: [2, 3, 8, 11, 16]
        }
        puts "The request object is #{request_object.to_json}"
        result = @rest_resource['add_request'].post(request_object.to_json, :content_type => :json, :accept => :json)
        puts "The result is #{result}"

      end

    end
  end
end