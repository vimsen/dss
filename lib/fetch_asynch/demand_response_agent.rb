require 'clustering/match_expected'

module FetchAsynch
  class DemandResponseAgent
    def initialize
      config = YAML.load_file('config/vimsen_hosts.yml')
      base_uri = config[Rails.env]["gdrms_host"]

      @rest_resource = RestClient::Resource.new(base_uri, :read_timeout => 10, :open_timeout => 10)

    end


    def eligible_prosumers(feeder_id, prosumer_category_prosumers)

      feeder_id.nil? ?
          prosumer_category_prosumers :
          feeder_id.count("_") == 2 ?
              prosumer_category_prosumers.where(feeder_id: feeder_id) :
              prosumer_category_prosumers.where("feeder_id ~* ?", "^#{feeder_id}_")

    end

    def select_prosumers(eligible_prosumers, dr_obj)
      case dr_obj.event_type
        when "target_match"
          target_matching_availability(eligible_prosumers, dr_obj)
        when "urgent_cut"
          urgent_cut(eligible_prosumers, dr_obj)
        when "planned_cut"
          planned_cut(eligible_prosumers, dr_obj)
        when "static_allocation"
          group = Prosumer.where(id: [62,64,67])
          [ group, Prosumer.where(cluster: 98) - group]
        when "greek_pilot_static"
          group = TempCluster.find_by(clustering: 7, name: :Greece).prosumers
          [ group, Prosumer.where(cluster: 98) - group]
        else
          raise "Wrong event type, received #{dr_obj.event_type}"
      end

    end

    def planned_cut(eligible_prosumers, dr_obj)
      res = []
      dr_stats = DataPoint.where(prosumer: eligible_prosumers,
                                 interval: dr_obj.interval,
                                 timestamp: dr_obj.starttime .. dr_obj.stoptime)
                     .where('dr is not null')
                     .group(:prosumer_id)
                     .order('average_dr desc')
                     .select('prosumer_id, avg(dr) as average_dr, avg(consumption) as average_consumption')

      total_reduction = 0
      target_reduction = dr_obj.dr_targets.map(&:volume).sum

      dr_stats.each do |d|
        break if total_reduction >= target_reduction
        res << Prosumer.find(d.prosumer_id)
        total_reduction += (d.average_dr||0) * (d.average_consumption||0)
      end
      [ res, eligible_prosumers - res]
    end

    def urgent_cut(eligible_prosumers, dr_obj)
      res = []
      dr_stats = DataPoint.where(prosumer: eligible_prosumers,
                                 interval: dr_obj.interval,
                                 timestamp: dr_obj.starttime .. dr_obj.stoptime)
                     .where('reliability is not null')
                     .group(:prosumer_id)
                     .order('average_reliability desc')
                     .select('prosumer_id, avg(dr) as average_dr, avg(reliability) as average_reliability, avg(consumption) as average_consumption')

      total_reduction = 0
      target_reduction = dr_obj.dr_targets.map(&:volume).sum

      dr_stats.each do |d|
        break if total_reduction >= target_reduction
        res << Prosumer.find(d.prosumer_id)
        total_reduction += (d.average_dr||0) * (d.average_consumption||0)
      end
      [ res, eligible_prosumers - res ]
    end


    def target_matching(eligible_prosumers, dr_obj)
      Rails.logger.debug "The targets are: #{dr_obj.dr_targets.pluck(:timestamp, :volume)}"
      tm = ClusteringModule::TargetMatcher.new prosumers: eligible_prosumers,
                                               startDate: dr_obj.starttime.to_datetime,
                                               endDate: dr_obj.stoptime.to_datetime,
                                               interval: dr_obj.interval.duration,
                                               targets: dr_obj.dr_targets.order(timestamp: :asc).map{|t| -t.volume}

      res = tm.run[:prosumers]
      [ res, eligible_prosumers - res ]
    end

    def target_matching_availability(eligible_prosumers, dr_obj)
      Rails.logger.debug "The targets are: #{dr_obj.dr_targets.pluck(:timestamp, :volume)}"
      tm = ClusteringModule::TargetMatcher.new prosumers: eligible_prosumers,
                                               startDate: dr_obj.starttime.to_datetime,
                                               endDate: dr_obj.stoptime.to_datetime,
                                               interval: dr_obj.interval.duration,
                                               targets: dr_obj.dr_targets.order(timestamp: :asc).map{|t| t.volume},
                                               prosumption_vector: :flex

      res = tm.run[:prosumers]
      [ res, eligible_prosumers - res]
    end

    def dr_activation(dr_obj, feeder_id, prosumer_category)
      Thread.new do
        begin
          ActiveRecord::Base.forbid_implicit_checkout_for_thread!

          ActiveRecord::Base.connection_pool.with_connection do
            el_prosumers = eligible_prosumers(feeder_id, prosumer_category.prosumers)
            Rails.logger.debug "The eligible prosumers are #{el_prosumers}"

            prosumers_primary, prosumers_secondary = select_prosumers el_prosumers, dr_obj

            DemandResponseProsumer.create prosumers_primary.map {|p| {demand_response: dr_obj, prosumer: p, drp_type: :primary}}
            DemandResponseProsumer.create! prosumers_secondary.map {|p| {demand_response: dr_obj, prosumer: p, drp_type: :secondary}}

            request_object = {
                start_time: dr_obj.starttime.to_datetime.to_s,
                interval: dr_obj.interval.duration,
                unit: "kW",
                target_values: dr_obj.dr_targets.order(timestamp: :asc).map{|t| t.volume},
                prosumers_primary: prosumers_primary.map(&:edms_id),
                prosumers_secondary: prosumers_secondary.map(&:edms_id),
                type: "demand reduction"
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
        rescue Exception => e
          Rails.logger.debug "EXCEPTION: #{e.inspect}"
          puts "EXCEPTION: #{e.inspect}"
          Rails.logger.debug "MESSAGE: #{e.message}"
          puts "MESSAGE: #{e.message}"
          Rails.logger.debug e.backtrace.join("\n")
          puts e.backtrace.join("\n")
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
      Rails.logger.debug "The plan id is: #{plan_id}"
      json = JSON.parse result
      # Rails.logger.debug json
      ActiveRecord::Base.connection_pool.with_connection do |conn|
        dr_obj = DemandResponse.find(demand_response_id)

        prosumers_ids = Prosumer.pluck(:edms_id, :id).to_h
        dr_obj.dr_targets.order(timestamp: :asc).each_with_index do |dr_target, i|
          json["planned_dr"].each do |k,v|
            Rails.logger.debug "k = #{k}, v= #{v[i]}"
            DrPlanned.find_or_create_by({
                                            prosumer_id: prosumers_ids[k],
                                            timestamp: dr_target.timestamp,
                                            demand_response_id: demand_response_id
                                        }) do |dr_planned|
              dr_planned.volume = v[i]
            end
          end
        end
        Rails.logger.debug "AAAAAAAAAAAAAAAAAA: #{json["actual_dr"]}"
        dr_obj.dr_targets.order(timestamp: :asc).each_with_index do |dr_target, i|
          json["actual_dr"].each do |k,v|
            Rails.logger.debug "k = #{k}, v= #{v[i]}"

            DrActual.find_or_create_by({
                                            prosumer_id: prosumers_ids[k],
                                            timestamp: dr_target.timestamp,
                                            demand_response_id: demand_response_id
                                        }) do |dr_actual|
              dr_actual.volume = v[i]
            end

          end
        end
      end
    end
  end
end