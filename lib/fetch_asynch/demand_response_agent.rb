module FetchAsynch
  class DemandResponseAgent
    def initialize
      config = YAML.load_file('config/vimsen_hosts.yml')
      base_uri = config[Rails.env]["gdrms_host"]

      @rest_resource = RestClient::Resource.new(base_uri, :read_timeout => 10, :open_timeout => 10)

    end

    def dr_activation(demand_response_id)
      ActiveRecord::Base.connection_pool.with_connection do
        dr_obj = DemandResponse.find(demand_response_id)
        request_object = {
            start_time: dr_obj.starttime.to_datetime.to_s,
            interval: dr_obj.interval.duration,
            unit: "kW",
            target_reduction: dr_obj.dr_targets.order(timestamp: :asc).map{|t| t.volume},
            prosumers_primary: [26, 27, 29, 30, 31],
            prosumers_secondary: [2, 3, 8, 11, 16]
        }
        Rails.logger.debug "The request object is #{request_object.to_json}"

        result = @rest_resource['add_request'].post(request_object.to_json, :content_type => :json, :accept => :json)

        #result = '{"status":"REGISTERED","plan_id":123456}';

        json = JSON.parse result
        if json["status"] == "REGISTERED"
          dr_obj.plan_id = json["plan_id"]
          dr_obj.save
          Rails.logger.debug "SUCEESS: The result is #{result}"
        else
          Rails.logger.debug "FAILURE: The result is #{result}"
        end
      end
    end

    def refresh_status(demand_response_id)

      plan_id=-1
      ActiveRecord::Base.connection_pool.with_connection do |conn|
        plan_id = DemandResponse.find(demand_response_id).plan_id
      end
      result = @rest_resource['status_check'].get params: {plan_id: plan_id}
      #t1 =  DateTime.parse("2016-03-11 11:30:00 +0200")
      #result = {
      #    status: "ok",
      #    start_time: t1,
      #    plan_id: 123456,
      #    interval: 900,
      #    unit: "kW",
      #    planned_dr: {
      #        "1": [10.20, 19.64, 18.60, 18.43, 20.41, 30.21, 11.41, 0.90, 14.78],
      #        "4": [14.50, 1.29, 14.28, 22.55, 7.58, 15.59, 18.02, 12.62, 16.17],
      #        "7": [18.72, 18.12, 10.40, 6.44, 19.24, 6.02, 7.34, 6.26, 17.51],
      #        "10": [6.91, 6.10, 12.85, 20.72, 17.95, 11.32, 10.37, 8.38, 12.69]
      #    },
      #    actual_dr: {
      #        "1": ((Time.zone.now.to_i - t1.to_i)/900.0).ceil.times.map{|i| rand(0.0..10.0)},
      #        "4": ((Time.zone.now.to_i - t1.to_i)/900.0).ceil.times.map{|i| rand(0.0..10.0)},
      #        "7": ((Time.zone.now.to_i - t1.to_i)/900.0).ceil.times.map{|i| rand(0.0..10.0)},
      #        "10": ((Time.zone.now.to_i - t1.to_i)/900.0).ceil.times.map{|i| rand(0.0..10.0)}
      #    }
      #}.to_json
      #sleep(3)
      Rails.logger.debug "RESULT:  #{result}"
      Rails.logger.debug "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAaaa, #{plan_id}"
      json = JSON.parse result
      Rails.logger.debug json
      ActiveRecord::Base.connection_pool.with_connection do |conn|
        i = 0
        dr_obj = DemandResponse.find(demand_response_id)
        Upsert.batch(conn, DrPlanned.table_name) do |upsert|
          dr_obj.dr_targets.order(timestamp: :asc).each do |dr_target|
            json["planned_dr"].each do |k,v|
              upsert.row({
                             prosumer_id: Prosumer.find(k).id,
                             timestamp: dr_target.timestamp,
                             demand_response_id: demand_response_id
                         },{
                             volume: v[i],
                             created_at: DateTime.now,
                             updated_at: DateTime.now
                         })
            end
            i += 1
          end
        end

        i = 0
        Upsert.batch(conn, DrActual.table_name) do |upsert|
          Rails.logger.debug "AAAAAAAAAAAAAAAAAA: #{json["actual_dr"]}"
          dr_obj.dr_targets.order(timestamp: :asc).each do |dr_target|
            json["actual_dr"].each do |k,v|
              Rails.logger.debug "#{k},#{v}"
              unless v[i].nil?
                upsert.row({
                               prosumer_id: Prosumer.find(k).id,
                               timestamp: dr_target.timestamp,
                               demand_response_id: demand_response_id,
                           },{
                               volume: v[i],
                               created_at: DateTime.now,
                               updated_at: DateTime.now
                           })
              end
            end
            i += 1
          end
        end
      end
    end
  end
end