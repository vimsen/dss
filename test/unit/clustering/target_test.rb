require 'test_helper'
require 'test_helper_with_pros_and_market_data'
require 'clustering/match_expected'

class TargetTest < ActiveSupport::TestCaseWithProsAndMarketData

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
    interval = 1.hour

    train_start = @startdate
    train_end = train_start + 4.days

    start = train_end + interval
    stop = start + ((points - 1) * interval).seconds


    u = SecureRandom.uuid


    total_timestamps_count = (stop.to_f - train_start.to_f)/interval + 1;
    puts "tr_st: #{train_start}, stop:#{stop}}, interval: #{interval}, ratio: #{total_timestamps_count}"
=begin

        ClusteringModule::TargetMatcher.new(
        startDate: train_start,
        endDate: stop,
        interval: interval
    ).timestamps
=end

    @prosumers.delete_if do |p|
      p.data_points.where(timestamp: train_start .. stop, interval: 2).count != total_timestamps_count
    end

    puts "prosumers: #{@prosumers.count}"

    # puts "tr_st: #{train_start}, ts_end:#{train_end}}, interval: #{interval}, ratio: #{(train_end.to_f - train_start.to_f)/interval}"
    train_timestamps = ClusteringModule::TargetMatcher.new(
        startDate: train_start,
        endDate: train_end,
        interval: interval,
        targets: ((train_end.to_f - train_start.to_f)/interval + 1).to_i.times.map {|ts| 20}
    ).timestamps


    CSV.open("results/input_#{u}.csv", "wb") do |csv|
      csv << @prosumers.map{|p| p.edms_id}
      train_timestamps.each do |ts|
        csv << @prosumers.map  do |p|
          pr = DataPoint.select('COALESCE(consumption,0) - COALESCE(production,0) as prosumption').find_by(prosumer: p, timestamp: ts, interval: Interval.find_by(duration: interval))
          pr.prosumption unless pr.nil?
        end
      end
    end

    system "./runmat_stf.sh #{points} #{u}"
    forecasts = CSV.read("results/output_#{u}.csv")
    puts JSON.pretty_generate forecasts


    prosumpton_vector = Hash[@prosumers.map {|p| [p.id, points.times.map{|ts| 0}]}]


    forecasts.each_with_index do |u, j|
      u.each_with_index do |pr, i|
        prosumpton_vector[@prosumers[i].id][j] = pr.to_f
      end
    end


    #CSV.open("input_#{u}.csv", "wb") do |csv|
    #  csv << Prosumer.all.pluck(:name)
    #  User.all.each do |user|
    #    csv << user.attributes.values
    #  end
    #end

    targets = points.times.map {|ts| 20}

    tm = ClusteringModule::TargetMatcher.new(
        prosumers: @prosumers,
        startDate: start,
        endDate: stop,
        interval: interval,
        targets: targets,
        prosumption_vector: prosumpton_vector
    )

    puts "Object created"
    results = tm.run
    puts JSON.pretty_generate results



    CSV.open("results/plot_data_#{u}.csv", "wb") do |csv|
      targets.each_with_index do |t,i|
        csv << [
            i,
            targets[i],
            results[:consumption][i][1],
            DataPoint.where(prosumer: results[:prosumers], timestamp: start + (i * interval).seconds, interval: Interval.find_by(duration: interval)).sum('COALESCE(consumption,0) - COALESCE(production,0)')
        ]
      end
    end


  end
end