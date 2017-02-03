require 'test_helper'
require 'test_helper_with_hedno_data'
require 'clustering/spectral_clustering'
require 'clustering/genetic_error_clustering2'

class HednoTest < ActiveSupport::TestCaseWithHednoData

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

  test "prosumers imported" do
    assert_equal 436, @prosumers.count, "We should have 436 prosumers"
  end

  test "count pv_lv_hedno datapoints" do
    assert_equal 40*(24*4*(365+366-31)), DataPoint.where(prosumer: 3000..4000).count, "pv_lv_hedno"
  end

  test "count aiolika_MV datapoints" do
    assert_equal 50*24*4*(365+366-31-30-31)-4*50, DataPoint.where(prosumer: 4000..5000).count, "aiolika_MV"
  end

  test "count emporikoi_MV datapoints" do
    assert_equal 50*24*4*(365+366-31-30-31)-4*50, DataPoint.where(prosumer: 5000..6000).count, "emporikoi_MV"
  end

  test "count biomhxanikoi datapoints" do  # <------------------
    assert_equal 50*24*4*(365+366-31-30-31)-5*50, DataPoint.where(prosumer: 6000..7000).count, "biomhxanikoi"
  end

  test "count biomhxanikoi_MV datapoints" do
    assert_equal 50*24*4*(365+366-31-30-31)-4*50, DataPoint.where(prosumer: 7000..8000).count, "biomhxanikoi_MV"
  end

  test "count epaggelmatikoi datapoints" do
    assert_equal 50*24*4*(365+366-31-30-31)-112581-5*50, DataPoint.where(prosumer: 8000..9000).count, "epaggelmatikoi"
  end

  test "count fwtismos_odwn_plateiwn datapoints" do
    assert_equal 46*24*4*(365+366-31-30-31)-5*46, DataPoint.where(prosumer: 9000..10000).count, "fwtismos_odwn_plateiwn"
  end

  test "count oikiakoi datapoints" do
    assert_equal 50*24*4*(365+366-31-30-31)-13440-5*50, DataPoint.where(prosumer: 10000..11000).count, "oikiakoi"
  end

  test "count photovoltaika_MV datapoints" do
    assert_equal 50*24*4*(365+366-31-30-31)-4*50, DataPoint.where(prosumer: 11000..12000).count, "photovoltaika_MV"
  end
      # puts JSON.pretty_generate @prosumers.map {|p| [p.id, p.data_points.count]}
  #  assert (DataPoint.where(prosumer: @prosumers).count.between?(240*(24*4*365 - 1), 240*24*4*365)), "We should have a full datapoint set"
  # end

  test "Run spectral clustering on hedno dataset" do
    spek = ClusteringModule::PositiveConsumptionSpectralClustering.new(prosumers: @prosumers, startDate: @startdate, endDate: @enddate)
    cl = Clustering.new(name: "Spectral", temp_clusters: spek.run(5))
    cl.save
    assert_equal(cl.temp_clusters.count, 5, "We should have 5 clusters")
    Rails.logger.debug "#{cl.temp_clusters.map{|tc| tc.prosumers.map{|p| @prosumers.index(Prosumer.find(p.id))}}}"
    stats = spek.stats(cl.temp_clusters.map{|tc| tc.prosumers.map{|p| @prosumers.index(Prosumer.find(p.id))}})
    Rails.logger.debug "#{stats}"
  end

  test "Run genetic clustering on hedno dataset" do
    gen = ClusteringModule::GeneticErrorClustering.new(prosumers: @prosumers, startDate: @startdate, endDate: @enddate)
    cl = Clustering.new(name: "Genetic", temp_clusters: gen.run(5))
    cl.save
    assert_equal(cl.temp_clusters.count, 5, "We should have 5 clusters")
    Rails.logger.debug "#{cl.temp_clusters.map{|tc| tc.prosumers.map{|p| @prosumers.index(Prosumer.find(p.id))}}}"
    Rails.logger.debug Market::Calculator.new(prosumers: cl.temp_clusters.first.prosumers,
                                              startDate: @startdate,
                                              endDate: @enddate)
                                         .calcCosts[:disaggregated]
  end

  test "Dump db to CSV" do
    # skip "Not a real test. This only needs to be run once."

    dbconn = ActiveRecord::Base.connection_pool.checkout
    conn  = dbconn.raw_connection
    File.open("data_points/hedno_prosumption_data.csv", "wb") do |f|
      conn.copy_data "COPY (SELECT id,
                         prosumer_id,
                         interval_id,
                         to_char(timezone('zulu', to_timestamp(date_part('epoch', timestamp))),'YYYY-MM-DDThh24:MI:SS+02:00') as timestamp,
                         production,
                         consumption
                       FROM data_points WHERE
                         prosumer_id BETWEEN 3001 AND 12050
                      ) TO STDOUT csv header;" do
        while row=conn.get_copy_data
          f.puts row
        end
      end
    end


    CSV.open("data_points/hedno_prosumers.csv", "wb") do |csv|
      csv << Prosumer.attribute_names
      Prosumer.order(id: :asc).each do |row|
        csv << row.attributes.values
      end
    end


    ActiveRecord::Base.connection_pool.checkin(dbconn)
  end

  test "statistics" do

    skip "don't overwrite output files"

    total_consumption = DataPoint.where(prosumer: @prosumers, interval: 1).group(:prosumer).sum(:consumption)
    total_production = DataPoint.where(prosumer: @prosumers, interval: 1).group(:prosumer).sum(:production)
    max_consumption = DataPoint.where(prosumer: @prosumers, interval: 1).group(:prosumer).maximum(:consumption)
    max_production = DataPoint.where(prosumer: @prosumers, interval: 1).group(:prosumer).maximum(:production)

    avg_total_consumption_vect = DataPoint.where(prosumer: @prosumers, interval: 1).group(:prosumer_id).group("extract(year from timestamp)").group("extract(month from timestamp)").sum(:consumption)
    avg_total_production_vect = DataPoint.where(prosumer: @prosumers, interval: 1).group(:prosumer_id).group("extract(year from timestamp)").group("extract(month from timestamp)").sum(:production)
    avg_max_consumption_vect = DataPoint.where(prosumer: @prosumers, interval: 1).group(:prosumer_id).group("extract(year from timestamp)").group("extract(month from timestamp)").maximum(:consumption)
    avg_max_production_vect = DataPoint.where(prosumer: @prosumers, interval: 1).group(:prosumer_id).group("extract(year from timestamp)").group("extract(month from timestamp)").maximum(:production)

    avg_total_consumption = @prosumers.map do |p|
      [ p,
        1.upto(12).sum do |m|
          avg_total_consumption_vect[[p.id,2015.to_f,m.to_f]] / 12.0
        end
      ]
    end.to_h

    avg_total_production = @prosumers.map do |p|
      [ p,
        1.upto(12).sum do |m|
          avg_total_production_vect[[p.id,2015.to_f,m.to_f]] / 12.0
        end
      ]
    end.to_h

    avg_max_consumption = @prosumers.map do |p|
      [ p,
        1.upto(12).sum do |m|
          (avg_max_consumption_vect[[p.id,2015.to_f,m.to_f]] || 0) / 12.0
        end
      ]
    end.to_h

    avg_max_production = @prosumers.map do |p|
      [ p,
        1.upto(12).sum do |m|
          (avg_max_production_vect[[p.id,2015.to_f,m.to_f]] || 0) / 12.0
        end
      ]
    end.to_h

    CSV.open( 'data_points/hedno_statistics.csv', 'w' ) do |csv|
      csv << ["prosumer_id", "prosumer_name", "location", "total_consumption", "total_production", "max_consumption", "max_production", "avg_total_consumption", "avg_total_production", "avg_max_consumption", "avg_max_production" ]

      @prosumers.each do |p|
        csv << [p.id, p.name, p.location, total_consumption[p], total_production[p], max_consumption[p], max_production[p],
                avg_total_consumption[p], avg_total_production[p], avg_max_consumption[p], avg_max_production[p]]
      end
    end

  end

end