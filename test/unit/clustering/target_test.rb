require 'test_helper'
require 'test_helper_with_hedno_data'
require 'clustering/match_expected'

class TargetTest < ActiveSupport::TestCaseWithHednoData

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  # Fake test
  test "target matcher" do

    points = 10
    # order = 200
    interval = 15.minutes
    train_duration = 7.days

    50.times do |i|
      10.step(300,10) do |order|

        train_start = rand(Time.at(@startdate)..Time.at(@enddate - train_duration - (points * interval).seconds)).beginning_of_hour
        train_end = train_start + train_duration

        start = train_end + interval
        stop = start + ((points - 1) * interval).seconds

        u = "#{points}_#{order}_#{SecureRandom.uuid}"

        total_timestamps_count = ((stop.to_f - train_start.to_f)/interval + 1).to_i;

        puts "#{@prosumers.map{|p| p.id}}"

        valid_prosumers = @prosumers.reject do |p|
          all_data_points = p.data_points.where(
              timestamp: train_start .. stop,
              interval: Interval.find_by(duration: interval)
          )
          max = p.data_points.where(
              timestamp: start .. stop,
              interval: Interval.find_by(duration: interval)
          ).maximum('COALESCE(consumption,0) - COALESCE(production,0)')
          min = p.data_points.where(
              timestamp: start .. stop,
              interval: Interval.find_by(duration: interval)
          ).minimum('COALESCE(consumption,0) - COALESCE(production,0)')
          puts "#{total_timestamps_count}: #{all_data_points.count} -- #{min} - #{max}"
          all_data_points.count != total_timestamps_count || (min == 0 && max == 0)
        end
        puts "tr_st: #{train_start}, stop:#{stop}}, interval: #{interval}, ratio: #{total_timestamps_count}, prosumers: #{valid_prosumers.count}"


        redo if valid_prosumers.count < 10

        # puts "tr_st: #{train_start}, ts_end:#{train_end}}, interval: #{interval}, ratio: #{(train_end.to_f - train_start.to_f)/interval}"
        train_timestamps = ClusteringModule::TargetMatcher.new(
            startDate: train_start,
            endDate: train_end,
            interval: interval,
            targets: ((train_end.to_f - train_start.to_f)/interval + 1).to_i.times.map {|ts| 20}
        ).timestamps


        CSV.open("results/input_#{u}.csv", "wb") do |csv|
          csv << valid_prosumers.map{|p| p.edms_id}
          train_timestamps.each do |ts|
            csv << valid_prosumers.map  do |p|
              pr = DataPoint.select('COALESCE(consumption,0) - COALESCE(production,0) as prosumption').find_by(prosumer: p, timestamp: ts, interval: Interval.find_by(duration: interval))
              pr.prosumption unless pr.nil?
            end
          end
        end

        system "./runmat_stf.sh #{points} #{u} #{order}"
        forecasts = CSV.read("results/output_#{u}.csv")
        puts JSON.pretty_generate forecasts


        prosumpton_vector = Hash[valid_prosumers.map {|p| [p.id, points.times.map{|ts| 0}]}]
        prosumpton_vector_no_forecast = Hash[valid_prosumers.map {|p| [p.id, points.times.map{|ts| DataPoint.select('COALESCE(consumption,0) - COALESCE(production,0) as prosumption').find_by(prosumer: p, timestamp: train_end, interval: Interval.find_by(duration: interval)).prosumption}]}]


        forecasts.each_with_index do |u, j|
          u.each_with_index do |pr, i|
            prosumpton_vector[valid_prosumers[i].id][j] = pr.to_f
          end
        end


        #CSV.open("input_#{u}.csv", "wb") do |csv|
        #  csv << Prosumer.all.pluck(:name)
        #  User.all.each do |user|
        #    csv << user.attributes.values
        #  end
        #end

        # DataPoint.where(prosumers: @prosumers, interval: Interval.find_by(duration: interval), timestamp: )

        # targets = points.times.map {|ts| rand(-25.0 .. -5.0)}

        targets = forecasts.map{|f| 0.25 * f.sum{|v| v.to_f}}

        tm = ClusteringModule::TargetMatcher.new(
            prosumers: valid_prosumers,
            startDate: start,
            endDate: stop,
            interval: interval,
            targets: targets,
            prosumption_vector: prosumpton_vector
        )

        puts "Object created"
        results = tm.run
        puts JSON.pretty_generate results

        tm2 = ClusteringModule::TargetMatcher.new(
            prosumers: valid_prosumers,
            startDate: start,
            endDate: stop,
            interval: interval,
            targets: targets,
            prosumption_vector: prosumpton_vector_no_forecast
        )

        puts "Object created"
        results_no_f = tm2.run
        puts JSON.pretty_generate results_no_f



        CSV.open("results/plot_data_#{u}.csv", "wb") do |csv|
          targets.each_with_index do |t,i|
            csv << [
                i,
                targets[i],
                results[:consumption][i][1],
                DataPoint.where(prosumer: results[:prosumers], timestamp: start + (i * interval).seconds, interval: Interval.find_by(duration: interval)).sum('COALESCE(consumption,0) - COALESCE(production,0)'),
                results_no_f[:consumption][i][1],
                DataPoint.where(prosumer: results_no_f[:prosumers], timestamp: start + (i * interval).seconds, interval: Interval.find_by(duration: interval)).sum('COALESCE(consumption,0) - COALESCE(production,0)')
            ]
          end
        end
      end
    end
  end
end