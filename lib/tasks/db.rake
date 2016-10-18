namespace :db do
  desc "TODO"
  task backup_to_initdata: :environment do
    puts "My environment is #{Rails.env}"
    FileUtils.rm_rf(Dir.glob('db/initdata/*'))

    Rails.application.eager_load!

    ActiveRecord::Base.descendants.reject do |t| 
      [User, DataPoint, Instance, Prosumer::HABTM_TempClusters].include? t
    end.each do |t|
      CSV.open("db/initdata/#{t}.csv", "wb") do |csv|
        csv << t.attribute_names
        t.all.order(t.attribute_names.include?("id") ? 'id ASC' : '').each do |row|
          csv << row.attributes.map{|k,v| v.try(:utc) || v}
        end
      end
    end
  end

  task :find_good_interval, [:cat] => :environment do |t, args|
    puts "My environment is #{Rails.env}, category is #{args[:cat]}"
    pc = ProsumerCategory.find args[:cat]

    first_time_stamp = DataPoint
                .where(prosumer: pc.prosumers, interval: 2)
                .minimum(:timestamp)

    puts "Data starting at #{first_time_stamp}"

    et = DateTime.now.beginning_of_day

    while et > first_time_stamp + 1.week
      st = et - 1.week

      prod = DataPoint.where(
                  prosumer: pc.prosumers,
                  interval: 2,
                  timestamp: st..et
      ).where('production > 0').group(:prosumer_id).count

      cons = DataPoint.where(
                  prosumer: pc.prosumers,
                  interval: 2,
                  timestamp: st..et
      ).where('consumption > 0').group(:prosumer_id).count

      res = pc.prosumers.map do |p|
        [
          p.id,
          (prod[p.id] || 0)+(cons[p.id] || 0),
          prod[p.id] || 0,
          cons[p.id] || 0
        ]
      end.sort_by{|p| -p[1]}.map do |p|
        p.join(":")
      end
      puts "start:#{st.to_date} end:#{et.to_date}, #{res.join " "}"

      et -= 1.day
    end
  end
end
