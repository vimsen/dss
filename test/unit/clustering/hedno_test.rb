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
    assert_equal 40*(24*4*(365+366-31)), DataPoint.where(prosumer: 3000..4000, interval: 1).count, "pv_lv_hedno"
  end

  test "count aiolika_MV datapoints" do
    assert_equal 50*24*4*(365+366-31-30-31)-4*50, DataPoint.where(prosumer: 4000..5000, interval: 1).count, "aiolika_MV"
  end

  test "count emporikoi_MV datapoints" do
    assert_equal 50*24*4*(365+366-31-30-31)-4*50, DataPoint.where(prosumer: 5000..6000, interval: 1).count, "emporikoi_MV"
  end

  test "count biomhxanikoi datapoints" do  # <------------------
    assert_equal 50*24*4*(365+366-31-30-31)-5*50, DataPoint.where(prosumer: 6000..7000, interval: 1).count, "biomhxanikoi"
  end

  test "count biomhxanikoi_MV datapoints" do
    assert_equal 50*24*4*(365+366-31-30-31)-4*50, DataPoint.where(prosumer: 7000..8000, interval: 1).count, "biomhxanikoi_MV"
  end

  test "count epaggelmatikoi datapoints" do
    assert_equal 50*24*4*(365+366-31-30-31)-112581-5*50, DataPoint.where(prosumer: 8000..9000, interval: 1).count, "epaggelmatikoi"
  end

  test "count fwtismos_odwn_plateiwn datapoints" do
    assert_equal 46*24*4*(365+366-31-30-31)-5*46, DataPoint.where(prosumer: 9000..10000, interval: 1).count, "fwtismos_odwn_plateiwn"
  end

  test "count oikiakoi datapoints" do
    assert_equal 50*24*4*(365+366-31-30-31)-13440-5*50, DataPoint.where(prosumer: 10000..11000, interval: 1).count, "oikiakoi"
  end

  test "count photovoltaika_MV datapoints" do
    assert_equal 50*24*4*(365+366-31-30-31)-4*50, DataPoint.where(prosumer: 11000..12000, interval: 1).count, "photovoltaika_MV"
  end
      # puts JSON.pretty_generate @prosumers.map {|p| [p.id, p.data_points.count]}
  #  assert (DataPoint.where(prosumer: @prosumers).count.between?(240*(24*4*365 - 1), 240*24*4*365)), "We should have a full datapoint set"
  # end

  test "Run spectral clustering on hedno dataset" do
    spek = ClusteringModule::PositiveConsumptionSpectralClustering.new(prosumers: @prosumers, startDate: @startdate, endDate: @startdate + 1.week)
    cl = Clustering.new(name: "Spectral", temp_clusters: spek.run(5))
    cl.save
    assert_equal(cl.temp_clusters.count, 5, "We should have 5 clusters")
    Rails.logger.debug "#{cl.temp_clusters.map{|tc| tc.prosumers.map{|p| @prosumers.index(Prosumer.find(p.id))}}}"
    stats = spek.stats(cl.temp_clusters.map{|tc| tc.prosumers.map{|p| @prosumers.index(Prosumer.find(p.id))}})
    Rails.logger.debug "#{stats}"
  end

  test "Run genetic clustering on hedno dataset" do
    gen = ClusteringModule::GeneticErrorClustering.new(prosumers: @prosumers, startDate: @startdate, endDate: @startdate + 1.week)
    cl = Clustering.new(name: "Genetic", temp_clusters: gen.run(5))
    cl.save
    assert_equal(cl.temp_clusters.count, 5, "We should have 5 clusters")
    Rails.logger.debug "#{cl.temp_clusters.map{|tc| tc.prosumers.map{|p| @prosumers.index(Prosumer.find(p.id))}}}"
    Rails.logger.debug Market::Calculator.new(prosumers: cl.temp_clusters.first.prosumers,
                                              startDate: @startdate + 1.week,
                                              endDate: @startdate + 2.weeks)
                                         .calcCosts[:disaggregated]
  end

  test "Dump db to CSV" do
    skip "Not a real test. This only needs to be run once."

    puts "DataPoint breakdown: #{DataPoint.where('prosumer_id BETWEEN 3001 AND 12050').group(:interval).order(interval_id: :asc).count.map{|k,v| [k.id, v]}.to_h}"

#     DataPoint.first.reload
    dbconn = ActiveRecord::Base.connection_pool.checkout
    conn  = dbconn.raw_connection
    File.open("data_points/hedno_prosumption_data.csv", "wb") do |f|
      conn.copy_data "COPY (SELECT prosumer_id,
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

    query = "SELECT ($1::TEXT), " +
        "tbl1.interval_id as interval, " +
        "to_char(timezone('zulu', to_timestamp(date_part('epoch', tbl1.timestamp))),'YYYY-MM-DDThh24:MI:SS+02:00') as timestamp, " +
        "tbl1.production as prod, " +
        "tbl2.consumption as cons " +
        "FROM data_points as tbl1 INNER JOIN data_points AS tbl2 " +
        "ON tbl1.interval_id = tbl2.interval_id AND tbl1.timestamp = tbl2.timestamp " +
        "WHERE tbl1.prosumer_id = ($2::INTEGER) AND tbl2.prosumer_id = ($3::INTEGER)"

    ActiveRecord::Base.connection.raw_connection.prepare('create_prosumers', query)

    CSV.open("data_points/hedno_prosumption_data.csv", "a") do |csv|

       [[1, 3001, 10002],
          [2, 3002, 10003],
          [3, 3003, 10004],
          [4, 3004, 10005],
          [5, 3005, 10006],
          [6, 3006, 10007],
          [7, 3007, 10008],
          [8, 3008, 10009],
          [9, 3009, 10011],
          [10, 3010, 10012],
          [11, 3011, 10013],
          [12, 3012, 10014],
          [13, 3013, 10015],
          [14, 3014, 10016],
          [15, 3015, 10017],
          [16, 3016, 10018],
          [17, 3017, 10019],
          [18, 3018, 10021],
          [19, 3019, 10022],
          [20, 3020, 10024],
          [21, 3021, 10025],
          [22, 3022, 10026],
          [23, 3023, 10028],
          [24, 3024, 10030],
          [25, 3025, 10031],
          [26, 3026, 10034],
          [27, 3027, 10036],
          [28, 3028, 10037],
          [29, 3029, 10038],
          [30, 3030, 10040],
          [31, 3031, 10041],
          [32, 3032, 10043],
          [33, 3033, 10044],
          [34, 11001, 5001],
          [35, 11002, 5002],
          [36, 11003, 5003],
          [37, 11004, 5004],
          [38, 11005, 5005],
          [39, 11006, 5006],
          [40, 11007, 5007],
          [41, 11008, 5011],
          [42, 11009, 5012],
          [43, 11010, 5016],
          [44, 11011, 5017],
          [45, 11012, 5018],
          [46, 11013, 5019],
          [47, 11014, 5020],
          [48, 11015, 5031],
          [49, 11016, 5032],
          [50, 11017, 5033],
          [51, 11018, 5034],
          [52, 11019, 5035],
          [53, 11020, 5036],
          [54, 11021, 5037],
          [55, 11022, 5038],
          [56, 11023, 5039],
          [57, 11024, 5043],
          [58, 11025, 5044],
          [59, 11026, 5046],
          [60, 11027, 5048],
          [61, 3033, 5050],
          [62, 11001, 7008],
          [63, 11002, 7010],
          [64, 11003, 7011],
          [65, 11004, 7012],
          [66, 11005, 7013],
          [67, 11006, 7014],
          [68, 11007, 7015],
          [69, 11008, 7016],
          [70, 11009, 7017],
          [71, 11010, 7018],
          [72, 11011, 7019],
          [73, 11012, 7020],
          [74, 11013, 7021],
          [75, 11014, 7024],
          [76, 11015, 7025],
          [77, 11016, 7026],
          [78, 11017, 7029],
          [79, 11018, 7030],
          [80, 11019, 7031],
          [81, 11020, 7032],
          [82, 11021, 7034],
          [83, 11022, 7035],
          [84, 11023, 7039],
          [85, 11024, 7042],
          [86, 11025, 7043],
          [87, 11026, 7046],
          [88, 11027, 7048],
          [89, 4002, 9001],
          [90, 4003, 9002],
          [91, 4004, 9003],
          [92, 4005, 9004],
          [93, 4006, 9005],
          [94, 4007, 9006],
          [95, 4008, 9007],
          [96, 4009, 9008],
          [97, 4010, 9009],
          [98, 4011, 9010],
          [99, 4012, 9011],
          [100, 4013, 9012],
          [101, 4014, 9013],
          [102, 4015, 9014],
          [103, 4016, 9015],
          [104, 4017, 9016],
          [105, 4018, 9017],
          [106, 4019, 9018],
          [107, 4020, 9019],
          [108, 4021, 9020],
          [109, 4022, 9021],
          [110, 4023, 9022],
          [111, 4024, 9023],
          [112, 4026, 9024],
          [113, 4027, 9025],
          [114, 4028, 9026],
          [115, 4029, 9027],
          [116, 4030, 9028],
          [117, 4031, 9029],
          [118, 4032, 9030],
          [119, 4033, 9031],
          [120, 4034, 9032],
          [121, 4036, 9033],
          [122, 4037, 9034],
          [123, 4038, 9035],
          [124, 4042, 9036]].each do |hp, prod, cons|
         res = ActiveRecord::Base.connection.raw_connection.exec_prepared('create_prosumers', ['HP_%04i' % hp, prod, cons])
         res.each do |r|
           csv << r.values
         end
       end

       query = "SELECT ($1::TEXT), " +
           "tbl1.interval_id as interval, " +
           "to_char(timezone('zulu', to_timestamp(date_part('epoch', tbl1.timestamp))),'YYYY-MM-DDThh24:MI:SS+02:00') as timestamp, " +
           "tbl1.production/2 as prod, " +
           "tbl2.consumption as cons " +
           "FROM data_points as tbl1 INNER JOIN data_points AS tbl2 " +
           "ON tbl1.interval_id = tbl2.interval_id AND tbl1.timestamp = tbl2.timestamp " +
           "WHERE tbl1.prosumer_id = ($2::INTEGER) AND tbl2.prosumer_id = ($3::INTEGER)"

       ActiveRecord::Base.connection.raw_connection.prepare('create_prosumers2', query)


       [[125, 3001, 9001],
       [126, 3002, 9002],
       [127, 3003, 9003],
       [128, 3004, 9004],
       [129, 3005, 9005],
       [130, 3006, 9006],
       [131, 3007, 9007],
       [132, 3008, 9008],
       [133, 3009, 9009],
       [134, 3010, 9010],
       [135, 3011, 9011],
       [136, 3012, 9012],
       [137, 3013, 9013],
       [138, 3014, 9014],
       [139, 3015, 9015],
       [140, 3016, 9016],
       [141, 3017, 9017],
       [142, 3018, 9018],
       [143, 3019, 9019],
       [144, 3020, 9020],
       [145, 3021, 9021],
       [146, 3022, 9022],
       [147, 3023, 9023],
       [148, 3024, 9024],
       [149, 3025, 9025],
       [150, 3026, 9026],
       [151, 3027, 9027],
       [152, 3028, 9028],
       [153, 3029, 9029],
       [154, 3030, 9030],
       [155, 3031, 9031],
       [156, 3032, 9032],
       [157, 3033, 9033],
       [158, 3034, 9034],
       [159, 3035, 9035],
       [160, 3036, 9036]].each do |hp, prod, cons|
        res = ActiveRecord::Base.connection.raw_connection.exec_prepared('create_prosumers2', ['HP_%04i' % hp, prod, cons])
        res.each do |r|
          csv << r.values
        end
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
