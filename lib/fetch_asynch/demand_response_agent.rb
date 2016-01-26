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
            start_time: dr_obj.starttime.to_datetime.to_s,
            interval: dr_obj.interval.duration,
            unit: "kW",
            target_reduction: dr_obj.dr_targets.order(timestamp: :asc).map{|t| t.volume},
            prosumers_primary: [1,4,7,10],
            prosumers_secondary: [2, 3, 8, 11, 16]
        }
        puts "The request object is #{request_object.to_json}"
        result = @rest_resource['add_request'].post(request_object.to_json, :content_type => :json, :accept => :json)

#         result = '{"status":"REGISTERED","plan_id":12345}';

        json = JSON.parse result
        if json["status"] == "REGISTERED"
          dr_obj.plan_id = json["plan_id"]
          dr_obj.save
          puts "SUCEESS: The result is #{result}"
        else
          puts "FAILURE: The result is #{result}"
        end
      end
    end

    def refresh_status(demand_response_id)
      ActiveRecord::Base.connection_pool.with_connection do |conn|
        dr_obj = DemandResponse.find(demand_response_id)
        result = @rest_resource['status_check'].get params: {plan_id: dr_obj.plan_id}
        # result = '{
        #              "status":"ok",
        #              "start_time":"2015-10-19T13:00:00.000+02:00",
        #             "plan_id":438912148531487,
        #             "interval":900,
        #             "unit":"kW",
        #             "planned_dr":{
        #               "1":[10.20, 19.64, 18.60, 18.43, 20.41, 30.21, 11.41, 0.90, 14.78],
        #               "4":[14.50, 1.29, 14.28, 22.55, 7.58, 15.59, 18.02, 12.62, 16.17],
        #               "7":[18.72, 18.12, 10.40, 6.44, 19.24, 6.02, 7.34, 6.26, 17.51],
        #               "10":[6.91, 6.10, 12.85, 20.72, 17.95, 11.32, 10.37, 8.38, 12.69]
        #             },
        #             "actual_dr":{
        #               "1":[0.02, 19.21, 17.77],
        #               "4":[13.62, 0.33, 14.18],
        #               "7":[17.74, 17.81, 9.49],
        #               "10":[6.86, 5.91, 12.24]
        #             }
        #         }'
        Rails.logger.debug "RESULT:  #{result}"
        Rails.logger.debug "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAaaa, #{dr_obj.plan_id}"
        json = JSON.parse result
        puts json

        i = 0
        Upsert.batch(conn, DrPlanned.table_name) do |upsert|
          dr_obj.dr_targets.order(timestamp: :asc).each do |dr_target|
            json["planned_dr"].each do |k,v|
              upsert.row({
                             prosumer_id: Prosumer.find_by_intelen_id(k).id,
                             timestamp: dr_target.timestamp,
                             demand_response_id: demand_response_id,
                             created_at: DateTime.now
                         },{
                             volume: v[i],
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
              puts "#{k},#{v}"
              unless v[i].nil?
                upsert.row({
                               prosumer_id: Prosumer.find_by_intelen_id(k).id,
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